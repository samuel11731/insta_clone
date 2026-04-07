// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {}

Hooks.ScrollToBottom = {
  mounted() {
    this.scrollToBottom()
  },
  updated() {
    this.scrollToBottom()
  },
  scrollToBottom() {
    this.el.scrollTop = this.el.scrollHeight
  }
}

Hooks.AudioRecorder = {
  mounted() {
    this.mediaRecorder = null;
    this.audioChunks = [];
    this.audioBlob = null;
    this.startTime = null;
    this.timerInterval = null;
    this.recordedDuration = 0;

    // Single click listener handles all three button actions
    this.el.addEventListener("click", (e) => {
      if (e.target.closest("#stop-recording-btn")) {
        this.stopRecording();
        return;
      }
      if (e.target.closest("#send-audio-btn")) {
        this.sendAudio();
        return;
      }
      if (e.target.closest("#cancel-audio-btn")) {
        this.cancelAudio();
        return;
      }
      // Click on mic button itself → start recording
      if (e.target.closest("#mic-btn")) {
        this.startRecording();
      }
    });
  },

  async startRecording() {
    if (this.mediaRecorder && this.mediaRecorder.state === "recording") return;
    if (this.audioBlob) return; // already have a pending recording
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      this.mediaRecorder = new MediaRecorder(stream);
      this.audioChunks = [];

      this.mediaRecorder.ondataavailable = (e) => this.audioChunks.push(e.data);

      this.mediaRecorder.onstop = () => {
        this.audioBlob = new Blob(this.audioChunks, { type: "audio/webm" });
        this.recordedDuration = Math.round((Date.now() - this.startTime) / 1000);

        if (this.recordedDuration < 1) {
          this.pushEvent("audio-too-short", {});
          this.resetState();
          return;
        }

        // Show the preview bar
        this.pushEvent("audio-preview-ready", { duration: this.recordedDuration });
      };

      this.startTime = Date.now();
      this.mediaRecorder.start();
      this.pushEvent("recording-started", {});

      this.timerInterval = setInterval(() => {
        const seconds = Math.floor((Date.now() - this.startTime) / 1000);
        this.pushEvent("recording-tick", { seconds });
      }, 1000);
    } catch (err) {
      console.error("Microphone error:", err);
    }
  },

  stopRecording() {
    if (this.mediaRecorder && this.mediaRecorder.state === "recording") {
      this.mediaRecorder.stop();
      this.mediaRecorder.stream.getTracks().forEach((t) => t.stop());
      clearInterval(this.timerInterval);
    }
  },

  async sendAudio() {
    if (!this.audioBlob) return;

    const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
    const formData = new FormData();
    formData.append("audio", new File([this.audioBlob], "voice_note.webm", { type: "audio/webm" }));

    try {
      const res = await fetch("/uploads/audio", {
        method: "POST",
        headers: { "x-csrf-token": csrfToken },
        body: formData
      });
      const { url } = await res.json();
      this.pushEvent("send-audio-url", { url, duration: this.recordedDuration });
    } catch (err) {
      console.error("Upload failed:", err);
    }

    this.resetState();
  },

  cancelAudio() {
    this.resetState();
    this.pushEvent("cancel-audio", {});
  },

  resetState() {
    this.audioBlob = null;
    this.audioChunks = [];
    this.recordedDuration = 0;
  }
};

// Auto-pause / auto-resume videos based on scroll visibility
Hooks.VideoPlayer = {
  mounted() {
    this.wasPlaying = true

    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting && entry.intersectionRatio >= 0.5) {
            // scrolled back into view — resume if it was playing before
            if (this.wasPlaying) {
              this.el.play().catch(() => { }) // catch autoplay block gracefully
            }
          } else if (!entry.isIntersecting) {
            // scrolled out of view — remember state and pause
            this.wasPlaying = !this.el.paused
            this.el.pause()
          }
        })
      },
      { threshold: [0, 0.5] }
    )
    this.observer.observe(this.el)
  },
  destroyed() {
    if (this.observer) this.observer.disconnect()
  }
}

Hooks.StoryScroller = {
  mounted() {
    const userId = this.el.dataset.activeUser;
    if (userId) {
      const targetGroup = document.getElementById(`story-group-${userId}`);
      if (targetGroup) {
        const container = document.getElementById("stories-scroll-container");
        if (container) {
          setTimeout(() => {
            container.scrollTo({ left: targetGroup.offsetLeft, behavior: 'instant' });
          }, 50);
        }
      }
    }
  }
};

Hooks.StoryAutoAdvance = {
  mounted() {
    this.timer = null;
    this.currentId = null;
    this.duration = 5000; // 5 seconds for image stories

    this.observe = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting && entry.intersectionRatio >= 0.8) {
          const storyEl = entry.target;
          const storyId = storyEl.id.replace('story-', '');
          const mediaType = storyEl.dataset.mediaType;
          this.startTimer(storyId, mediaType);
        } else if (!entry.isIntersecting) {
          this.clearTimer();
        }
      });
    }, { threshold: 0.8 });

    // Observe all story slides
    setTimeout(() => {
      document.querySelectorAll('[id^="story-"]').forEach(el => {
        if (el.id !== 'story-viewer-modal') this.observe.observe(el);
      });
    }, 100);
  },

  startTimer(storyId, mediaType) {
    if (storyId === this.currentId) return; // already running for this story
    this.clearTimer();
    this.currentId = storyId;

    const progressBar = document.getElementById(`progress-bar-${storyId}`);
    if (!progressBar) return;

    if (mediaType === 'video') {
      const video = document.querySelector(`#story-${storyId} video`);
      if (video) {
        progressBar.style.width = '0%';
        this.videoListener = () => {
          const pct = (video.currentTime / video.duration) * 100;
          progressBar.style.transition = 'none';
          progressBar.style.width = pct + '%';
        };
        video.addEventListener('timeupdate', this.videoListener);
      }
      return; // videos don't auto-advance
    }

    // Image story: animate progress bar over 5 seconds then advance
    progressBar.style.transition = 'none';
    progressBar.style.width = '0%';
    requestAnimationFrame(() => {
      progressBar.style.transition = `width ${this.duration}ms linear`;
      progressBar.style.width = '100%';
    });

    this.timer = setTimeout(() => {
      const container = document.getElementById('stories-scroll-container');
      if (!container) return;

      // Get all story slides
      const allSlides = Array.from(document.querySelectorAll('[id^="story-"]'))
        .filter(el => el.id !== 'story-viewer-modal' && !el.id.startsWith('story-group-'));

      const currentIndex = allSlides.findIndex(el => el.id === `story-${this.currentId}`);
      const isLast = currentIndex >= allSlides.length - 1;

      if (isLast) {
        // Last story — close the entire viewer
        this.pushEvent('close-stories', {});
      } else {
        container.scrollBy({ left: window.innerWidth, behavior: 'smooth' });
      }
    }, this.duration);
  },

  clearTimer() {
    if (this.timer) { clearTimeout(this.timer); this.timer = null; }
    this.currentId = null;
  },

  destroyed() {
    this.clearTimer();
    if (this.observe) this.observe.disconnect();
  }
};

window.addEventListener("click", e => {
  const playBtn = e.target.closest(".audio-play-btn");
  if (!playBtn) return;

  const audioId = playBtn.dataset.audioId;
  const audio = document.getElementById(`audio-${audioId}`);
  if (!audio) return;

  // Find the progress fill bar (sibling inside the same flex container)
  const container = playBtn.closest(".audio-bubble-container");
  const progressFill = container ? container.querySelector(".audio-progress-fill") : null;
  const timeLabel = container ? container.querySelector(".audio-time-label") : null;

  function formatTime(secs) {
    const s = Math.floor(secs);
    return s < 60 ? `${s}s` : `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
  }

  if (audio.paused) {
    // Pause all other audios first
    document.querySelectorAll("audio").forEach(a => {
      if (a !== audio) {
        a.pause();
        const otherBtn = document.querySelector(`.audio-play-btn[data-audio-id="${a.id.replace('audio-', '')}"]`);
        if (otherBtn) {
          otherBtn.querySelector('.play-icon').classList.remove('hidden');
          otherBtn.querySelector('.pause-icon').classList.add('hidden');
        }
      }
    });

    audio.play();
    playBtn.querySelector('.play-icon').classList.add('hidden');
    playBtn.querySelector('.pause-icon').classList.remove('hidden');

    // Drive progress bar via timeupdate
    audio._timeupdateHandler = () => {
      if (!audio.duration) return;
      const pct = (audio.currentTime / audio.duration) * 100;
      if (progressFill) progressFill.style.width = pct + "%";
      if (timeLabel) timeLabel.textContent = formatTime(audio.currentTime);
    };
    audio.addEventListener("timeupdate", audio._timeupdateHandler);

    audio.onended = () => {
      playBtn.querySelector('.play-icon').classList.remove('hidden');
      playBtn.querySelector('.pause-icon').classList.add('hidden');
      if (progressFill) progressFill.style.width = "0%";
      if (timeLabel && audio.duration) timeLabel.textContent = formatTime(audio.duration);
      audio.removeEventListener("timeupdate", audio._timeupdateHandler);
    };
  } else {
    audio.pause();
    playBtn.querySelector('.play-icon').classList.remove('hidden');
    playBtn.querySelector('.pause-icon').classList.add('hidden');
  }
});

// Colocated hooks support
try {
  const { hooks: colocatedHooks } = require("phoenix-colocated/insta_clone");
  Object.assign(Hooks, colocatedHooks);
} catch (e) {
  // Ignore if colocated hooks are not available
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
window.liveSocket = liveSocket

window.addEventListener("phx:scroll-to-comment", (e) => {
  setTimeout(() => {
    const commentEl = document.getElementById(e.detail.id);

    if (commentEl) {
      const scrollArea = document.getElementById("comments-scroll-area-desktop") ||
        document.getElementById("comments-scroll-area-mobile") ||
        document.getElementById("comments-scroll-area");

      if (scrollArea) {
        const scrollAreaRect = scrollArea.getBoundingClientRect();
        const commentRect = commentEl.getBoundingClientRect();
        const relativeTop = commentRect.top - scrollAreaRect.top + scrollArea.scrollTop - 20;

        scrollArea.scrollTo({ top: relativeTop, behavior: 'smooth' });
      } else {
        commentEl.scrollIntoView({ behavior: "smooth", block: "center" });
      }

      // Highlight briefly
      commentEl.classList.add("bg-gray-50", "transition-colors", "duration-500");
      setTimeout(() => commentEl.classList.remove("bg-gray-50", "transition-colors", "duration-500"), 2000);
    }

    // Clear the input field
    const inputs = document.querySelectorAll("input[name='comment[body]']");
    inputs.forEach(input => input.value = "");
  }, 50);
});
