// EXACT COPY from Janus Official VideoRoom Demo - No More Guessing!
import { useEffect, useRef, useState, useCallback } from 'react';
declare global {
  const Janus: any;
}
import { getUserIdFromToken } from './jwt-wrapper';

interface UseJanusVoiceProps {
  roomId: string | null;
  enabled: boolean;
}

export function useJanusVoice({ roomId, enabled }: UseJanusVoiceProps) {
  const [isMuted, setIsMuted] = useState(true);
  const [isConnected, setIsConnected] = useState(false);
  
  const janusRef = useRef<any>(null);
  const sfutestRef = useRef<any>(null); // Publisher handle (like official demo)
  const localStreamRef = useRef<MediaStream | null>(null);
  const remoteFeedsRef = useRef<Map<number, any>>(new Map());
  
  // Convert room to number (same as before - this works)
  const getRoomNumber = useCallback(() => {
    if (!roomId) return 0;
    const hash = roomId.split('').reduce((a, b) => {
      a = ((a << 5) - a) + b.charCodeAt(0);
      return a & a;
    }, 0);
    return Math.abs(hash) % 1000000;
  }, [roomId]);

  useEffect(() => {
    if (!enabled || !roomId) return;
    
    let janus: any = null;
    const myroom = getRoomNumber();
    let mypvtid: number | null = null;

    const init = async () => {
      try {
        // Initialize Janus (EXACT copy from official demo)
        await new Promise<void>((resolve) => {
          Janus.init({
            debug: "all",
            callback: resolve
          });
        });

        // Create session (EXACT copy from official demo)
        janus = new Janus({
          server: `${window.location.protocol === 'https:' ? 'wss:' : 'ws:'}//${window.location.host}/janus-ws`,
          success: function() {
            console.log("✅ Janus session created");
            janusRef.current = janus;
            
            // Attach publisher (EXACT copy from official demo)
            janus.attach({
              plugin: "janus.plugin.videoroom",
              success: function(pluginHandle: any) {
                console.log("✅ Publisher attached");
                sfutestRef.current = pluginHandle;
                
                // Try to create room first, then join (working version)
                const create = {
                  request: "create",
                  room: myroom,
                  publishers: 50,
                  audiocodec: "opus",
                  description: `Voice room ${roomId}`,
                  record: false,
                  permanent: false
                };
                
                pluginHandle.send({
                  message: create,
                  success: function() {
                    console.log("✅ Room created");
                    joinAsPublisher();
                  },
                  error: function() {
                    // Room exists, just join
                    console.log("Room exists, joining...");
                    joinAsPublisher();
                  }
                });
                
                function joinAsPublisher() {
                  const register = {
                    request: "join",
                    room: myroom,
                    ptype: "publisher",
                    display: getUserIdFromToken() || "Anonymous"
                  };
                  pluginHandle.send({ message: register });
                }
              },
              error: function(error: any) {
                console.error("❌ Error attaching plugin:", error);
              },
              onmessage: function(msg: any, jsep: any) {
                console.log("Publisher message:", msg);
                const event = msg["videoroom"];
                
                if (event === "joined") {
                  console.log("✅ Joined as publisher");
                    mypvtid = msg["private_id"];
                  setIsConnected(true);
                  
                  // Check for existing publishers (EXACT copy)
                  if (msg["publishers"]) {
                    msg["publishers"].forEach((publisher: any) => {
                      console.log("Found existing publisher:", publisher);
                      newRemoteFeed(publisher.id, publisher.display);
                    });
                  }
                  
                  // Start publishing our stream (EXACT copy)
                  publishOwnFeed(true);
                  
                } else if (event === "event") {
                  // Handle new publishers joining (EXACT copy)
                  if (msg["publishers"]) {
                    msg["publishers"].forEach((publisher: any) => {
                      console.log("New publisher joined:", publisher);
                      newRemoteFeed(publisher.id, publisher.display);
                    });
                  }
                  
                  // Handle publishers leaving (EXACT copy)
                  if (msg["leaving"]) {
                    const leaving = msg["leaving"];
                    console.log("Publisher leaving:", leaving);
                    const remoteFeed = remoteFeedsRef.current.get(leaving);
                    if (remoteFeed) {
                      remoteFeed.detach();
                      remoteFeedsRef.current.delete(leaving);
                    }
                  }
                }
                
                if (jsep) {
                  console.log("Publisher handling JSEP:", jsep);
                  sfutestRef.current.handleRemoteJsep({ jsep: jsep });
                }
              },
              onlocalstream: function(stream: MediaStream) {
                console.log("✅ Local stream ready");
                localStreamRef.current = stream;
                // Start muted and sync state
                setTimeout(() => {
                  if (sfutestRef.current) {
                    sfutestRef.current.muteAudio();
                    setIsMuted(true);
                    console.log("🔇 Started muted");
                  }
                }, 100);
              },
              oncleanup: function() {
                console.log("Publisher cleanup");
                setIsConnected(false);
              }
            });
          },
          error: function(error: any) {
            console.error("❌ Janus error:", error);
          },
          destroyed: function() {
            console.log("Janus session destroyed");
          }
        });
        
      } catch (err) {
        console.error("❌ Failed to init Janus:", err);
      }
    };

    // Publish own feed (official demo pattern with tracks)
    const publishOwnFeed = (useAudio: boolean) => {
      const tracks = [
        { type: 'audio', capture: useAudio, recv: false }
      ];
      
      sfutestRef.current.createOffer({
        tracks: tracks,
        success: function(jsep: any) {
          console.log("✅ Offer created with tracks");
          const publish = { 
            request: "configure", 
            audio: useAudio, 
            video: false,
            audiocodec: "opus"
          };
          sfutestRef.current.send({ message: publish, jsep: jsep });
        },
        error: function(error: any) {
          console.error("❌ createOffer error:", error);
        }
      });
    };

    // Create new remote feed (EXACT copy from official demo structure)
    const newRemoteFeed = (id: number, display: string) => {
      console.log("Creating remote feed for:", id, display);
      let remoteFeed: any = null;
      
      janus.attach({
        plugin: "janus.plugin.videoroom",
        success: function(pluginHandle: any) {
          console.log("✅ Remote feed attached for", id);
          remoteFeed = pluginHandle;
          remoteFeed.rfid = id;
          remoteFeed.rfdisplay = display;
          remoteFeed.remoteTracks = {};
          remoteFeedsRef.current.set(id, remoteFeed);
          
          // Subscribe to feed (EXACT copy from official demo)
          const subscribe = {
            request: "join",
            room: myroom,
            ptype: "subscriber",
            feed: id,
            private_id: mypvtid
          };
          remoteFeed.send({ message: subscribe });
        },
        error: function(error: any) {
          console.error("❌ Error attaching remote feed:", error);
        },
        onmessage: function(msg: any, jsep: any) {
          console.log("Remote feed message:", msg);
          const event = msg["videoroom"];
          
          if (event === "attached") {
            console.log("✅ Successfully attached to feed", id);
          }
          
          if (jsep) {
            console.log("Remote feed handling JSEP");
            // EXACT copy from official demo
            remoteFeed.createAnswer({
              jsep: jsep,
              media: { audioSend: false, videoSend: false },
              success: function(jsep: any) {
                console.log("✅ Answer created for feed", id);
                const body = { request: "start", room: myroom };
                remoteFeed.send({ message: body, jsep: jsep });
              },
              error: function(error: any) {
                console.error("❌ createAnswer error:", error);
              }
            });
          }
        },
        // EXACT copy from official demo - this is the key callback!
        onremotetrack: function(track: MediaStreamTrack, mid: string, on: boolean) {
          console.log("Remote feed #" + id + ", remote track (mid=" + mid + ") " + (on ? "added" : "removed") + ":", track);
          
          if(!on) {
            // Track removed, get rid of the stream and the rendering
            const audio = document.getElementById(`remotevideo${id}-${mid}`);
            if(audio) audio.remove();
            delete remoteFeed.remoteTracks[mid];
            return;
          }
          
          // If we're here, a new track was added
          if(document.getElementById(`remotevideo${id}-${mid}`)) return;
          
          if(track.kind === "audio") {
            // EXACT copy from official demo - create stream from track
            const stream = new MediaStream([track]);
            remoteFeed.remoteTracks[mid] = stream;
            console.log("✅ Created remote audio stream:", stream);
            
            // Create hidden audio element (EXACT copy)
            const audio = document.createElement('audio');
            audio.className = 'hide';
            audio.id = `remotevideo${id}-${mid}`;
            audio.autoplay = true;
            audio.setAttribute('playsinline', 'true');
            document.body.appendChild(audio);
            
            // Use Janus.attachMediaStream (EXACT copy from official demo)
            Janus.attachMediaStream(audio, stream);
            console.log("✅ Audio attached for feed", id);
          }
        },
        oncleanup: function() {
          console.log("Remote feed cleanup:", id);
          // Clean up all audio elements for this feed
          Object.keys(remoteFeed.remoteTracks || {}).forEach(mid => {
            const audio = document.getElementById(`remotevideo${id}-${mid}`);
            if(audio) audio.remove();
          });
          remoteFeedsRef.current.delete(id);
        }
      });
    };

    init();

    // Cleanup (EXACT copy structure)
    return () => {
      if (localStreamRef.current) {
        localStreamRef.current.getTracks().forEach(track => track.stop());
      }
      
      remoteFeedsRef.current.forEach(remoteFeed => {
        remoteFeed.detach();
      });
      remoteFeedsRef.current.clear();
      
      if (sfutestRef.current) {
        sfutestRef.current.detach();
      }
      
      if (janus) {
        janus.destroy();
      }
    };
  }, [enabled, roomId, getRoomNumber]);

  // Toggle mute using Janus built-in methods (official way)
  const toggleMute = useCallback(() => {
    if (sfutestRef.current) {
      const currentlyMuted = sfutestRef.current.isAudioMuted();
      console.log("🔄 Current mute state:", currentlyMuted);
      
      if (currentlyMuted) {
        sfutestRef.current.unmuteAudio();
        setIsMuted(false);
        console.log("🔊 UNMUTED via Janus");
      } else {
        sfutestRef.current.muteAudio();
        setIsMuted(true);
        console.log("🔇 MUTED via Janus");
      }
    } else {
      console.log("❌ No publisher handle found");
    }
  }, []);

  return {
    isConnected,
    isMuted,
    toggleMute,
    leaveVoice: () => {
      // Implementation for leaving voice
    }
  };
}