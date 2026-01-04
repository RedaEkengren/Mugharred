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
  const [isVideoEnabled, setIsVideoEnabled] = useState(false);
  
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
                  
                  // Start publishing our stream (with optional video)
                  publishOwnFeed(true, isVideoEnabled);
                  
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
                
                // Add local video to PIP - check for video tracks instead of state
                const localPip = document.getElementById('local-video-pip');
                const hasVideoTrack = stream.getVideoTracks().length > 0;
                
                if (localPip && hasVideoTrack) {
                  const video = document.createElement('video');
                  video.id = 'local-video-element';
                  video.autoplay = true;
                  video.muted = true; // Always mute own video to prevent echo
                  video.setAttribute('playsinline', 'true');
                  video.style.cssText = `
                    width: 100%;
                    height: 100%;
                    object-fit: cover;
                  `;
                  
                  // Clear placeholder and add video
                  localPip.innerHTML = '';
                  localPip.appendChild(video);
                  
                  // Attach local stream
                  Janus.attachMediaStream(video, stream);
                  console.log("✅ Local video added to PIP (detected video track)");
                } else if (localPip && !hasVideoTrack) {
                  // Audio-only mode - keep placeholder
                  console.log("🎤 Audio-only local stream (no video track)");
                }
                
                // Sync state with actual Janus mute status
                setTimeout(() => {
                  if (sfutestRef.current) {
                    const actuallyMuted = sfutestRef.current.isAudioMuted();
                    console.log("🔄 Actual Janus mute state:", actuallyMuted);
                    setIsMuted(actuallyMuted);
                    
                    // If not muted, mute it to start properly
                    if (!actuallyMuted) {
                      sfutestRef.current.muteAudio();
                      setIsMuted(true);
                      console.log("🔇 Force muted at start");
                    }
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
    const publishOwnFeed = (useAudio: boolean, useVideo: boolean = false) => {
      const tracks = [
        { type: 'audio', capture: useAudio, recv: false }
      ];
      
      if (useVideo) {
        tracks.push({ type: 'video', capture: true, recv: false });
      }
      
      sfutestRef.current.createOffer({
        tracks: tracks,
        success: function(jsep: any) {
          console.log("✅ Offer created with tracks", { audio: useAudio, video: useVideo });
          const publish = { 
            request: "configure", 
            audio: useAudio, 
            video: useVideo,
            audiocodec: "opus",
            videocodec: useVideo ? "vp8" : undefined
          };
          sfutestRef.current.send({ message: publish, jsep: jsep });
        },
        error: function(error: any) {
          console.error("❌ createOffer error:", error);
        }
      });
    };

    // Speaker switching function for mobile video layout
    const switchMainSpeaker = (newSpeakerId: number) => {
      console.log(`🔄 Switching main speaker to user ${newSpeakerId}`);
      
      const mainSpeaker = document.getElementById('main-speaker-video');
      const thumbnailsBar = document.getElementById('video-thumbnails-bar');
      
      if (!mainSpeaker || !thumbnailsBar) return;
      
      // Find current main speaker and new thumbnail
      const currentMain = mainSpeaker.querySelector('.main-speaker') as HTMLVideoElement;
      const newMainThumbnail = thumbnailsBar.querySelector(`[data-feed-id="${newSpeakerId}"]`) as HTMLVideoElement;
      
      if (!currentMain || !newMainThumbnail) return;
      
      // Get current main speaker's feed ID
      const currentSpeakerId = currentMain.dataset.feedId;
      
      // Clone both video elements to preserve streams
      const newMainVideo = newMainThumbnail.cloneNode(true) as HTMLVideoElement;
      const newThumbnailVideo = currentMain.cloneNode(true) as HTMLVideoElement;
      
      // Update classes and styles for new main speaker
      newMainVideo.className = 'remote-video-element main-speaker';
      newMainVideo.style.cssText = `
        width: 100%;
        height: 100%;
        object-fit: cover;
        background: #000;
        position: absolute;
        top: 0;
        left: 0;
        z-index: 1;
      `;
      
      // Update classes and styles for new thumbnail
      newThumbnailVideo.className = 'remote-video-element thumbnail';
      newThumbnailVideo.style.cssText = `
        width: 100%;
        height: 100%;
        object-fit: cover;
      `;
      
      // Replace main speaker
      mainSpeaker.removeChild(currentMain);
      mainSpeaker.appendChild(newMainVideo);
      
      // Replace thumbnail
      const oldThumbnailContainer = newMainThumbnail.parentElement;
      if (oldThumbnailContainer) {
        const newThumbnailContainer = document.createElement('div');
        newThumbnailContainer.className = 'video-thumbnail-container';
        newThumbnailContainer.style.cssText = `
          width: 60px;
          height: 80px;
          border-radius: 8px;
          overflow: hidden;
          border: 2px solid rgba(255, 255, 255, 0.3);
          cursor: pointer;
          flex-shrink: 0;
          background: #1f2937;
        `;
        
        newThumbnailContainer.addEventListener('click', () => switchMainSpeaker(parseInt(currentSpeakerId || '0')));
        newThumbnailContainer.appendChild(newThumbnailVideo);
        
        thumbnailsBar.replaceChild(newThumbnailContainer, oldThumbnailContainer);
      }
      
      console.log(`✅ Speaker switched: ${newSpeakerId} is now main speaker`);
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
          } else if(track.kind === "video") {
            // Video track handling with Speaker Focus layout for mobile-first
            const stream = new MediaStream([track]);
            remoteFeed.remoteTracks[mid] = stream;
            console.log("✅ Created remote video stream:", stream);
            
            // Check if we're in video call overlay with speaker focus
            const mainSpeaker = document.getElementById('main-speaker-video');
            const thumbnailsBar = document.getElementById('video-thumbnails-bar');
            
            if (mainSpeaker && thumbnailsBar) {
              // Count existing remote video feeds to determine layout
              const existingVideos = document.querySelectorAll('.remote-video-element').length;
              console.log(`📊 Video users: ${existingVideos + 1}, Feed ID: ${id}`);
              
              // Check 3-user video limit
              if (existingVideos >= 3) {
                console.log("❌ Video limit reached (3 users max), keeping audio only");
                // TODO: Show notification "Video limit reached, audio only"
                return;
              }
              
              if (existingVideos === 0) {
                // First remote user - make them main speaker
                const video = document.createElement('video');
                video.className = 'remote-video-element main-speaker';
                video.id = `remotevideo${id}-${mid}`;
                video.autoplay = true;
                video.setAttribute('playsinline', 'true');
                video.dataset.feedId = id.toString();
                video.style.cssText = `
                  width: 100%;
                  height: 100%;
                  object-fit: cover;
                  background: #000;
                  position: absolute;
                  top: 0;
                  left: 0;
                  z-index: 1;
                `;
                
                // Replace placeholder with main speaker
                const placeholder = document.getElementById('speaker-placeholder');
                if (placeholder) {
                  placeholder.style.display = 'none';
                }
                mainSpeaker.appendChild(video);
                
                Janus.attachMediaStream(video, stream);
                console.log(`✅ User ${id} set as main speaker`);
                
              } else {
                // Additional users - add as thumbnails
                const video = document.createElement('video');
                video.className = 'remote-video-element thumbnail';
                video.id = `remotevideo${id}-${mid}`;
                video.autoplay = true;
                video.setAttribute('playsinline', 'true');
                video.dataset.feedId = id.toString();
                
                // Create thumbnail container
                const thumbContainer = document.createElement('div');
                thumbContainer.className = 'video-thumbnail-container';
                thumbContainer.style.cssText = `
                  width: 60px;
                  height: 80px;
                  border-radius: 8px;
                  overflow: hidden;
                  border: 2px solid rgba(255, 255, 255, 0.3);
                  cursor: pointer;
                  flex-shrink: 0;
                  background: #1f2937;
                `;
                
                video.style.cssText = `
                  width: 100%;
                  height: 100%;
                  object-fit: cover;
                `;
                
                // Add click handler to switch speaker
                thumbContainer.addEventListener('click', () => switchMainSpeaker(id));
                
                thumbContainer.appendChild(video);
                thumbnailsBar.appendChild(thumbContainer);
                thumbnailsBar.style.display = 'flex';
                
                Janus.attachMediaStream(video, stream);
                console.log(`✅ User ${id} added as thumbnail`);
              }
              
            } else {
              // Fallback for non-overlay mode - floating video
              const video = document.createElement('video');
              video.className = 'remote-video-floating';
              video.id = `remotevideo${id}-${mid}`;
              video.autoplay = true;
              video.setAttribute('playsinline', 'true');
              video.style.cssText = `
                width: 300px;
                height: 200px;
                position: fixed;
                bottom: 10px;
                right: ${10 + (id % 3) * 320}px;
                z-index: 9999;
                border: 2px solid #10b981;
                border-radius: 12px;
                object-fit: cover;
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
              `;
              document.body.appendChild(video);
              
              // Use Janus.attachMediaStream
              Janus.attachMediaStream(video, stream);
              console.log("✅ Remote video attached as floating element");
            }
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

  // Toggle video with proper error handling for mobile permissions
  const toggleVideo = useCallback(async () => {
    const newVideoState = !isVideoEnabled;
    
    // If enabling video, check camera permissions first
    if (newVideoState) {
      try {
        // Test camera access using modern API
        const stream = await navigator.mediaDevices.getUserMedia({ 
          video: { facingMode: 'user' }, 
          audio: false 
        });
        // Stop test stream immediately
        stream.getTracks().forEach(track => track.stop());
        console.log("✅ Camera permission granted");
      } catch (error) {
        console.error("❌ Camera permission denied or not available:", error);
        alert("Camera access denied or not available. Please check your browser permissions.");
        return; // Don't enable video if permission denied
      }
    }
    
    setIsVideoEnabled(newVideoState);
    console.log(newVideoState ? "📹 Video enabled" : "📹 Video disabled");
    
    // Republish with new video state
    if (sfutestRef.current && isConnected) {
      const publishOwnFeed = (useAudio: boolean, useVideo: boolean = false) => {
        const tracks = [
          { type: 'audio', capture: useAudio, recv: false }
        ];
        
        if (useVideo) {
          tracks.push({ type: 'video', capture: true, recv: false });
        }
        
        sfutestRef.current.createOffer({
          tracks: tracks,
          success: function(jsep: any) {
            console.log("✅ Offer created with tracks", { audio: useAudio, video: useVideo });
            const publish = { 
              request: "configure", 
              audio: useAudio, 
              video: useVideo,
              audiocodec: "opus",
              videocodec: useVideo ? "vp8" : undefined
            };
            sfutestRef.current.send({ message: publish, jsep: jsep });
          },
          error: function(error: any) {
            console.error("❌ createOffer error:", error);
          }
        });
      };
      
      publishOwnFeed(true, newVideoState);
    }
  }, [isVideoEnabled, isConnected]);

  return {
    isConnected,
    isMuted,
    isVideoEnabled,
    toggleMute,
    toggleVideo,
    leaveVoice: () => {
      // Implementation for leaving voice
    }
  };
}