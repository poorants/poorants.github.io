// Likes (anonymous) + comments (Google One Tap, inline one-level replies) + navbar auth avatar.
// Loaded globally on every page (head-end). Navbar avatar everywhere; likes/comments where .reactions exists.
import { initializeApp } from "https://www.gstatic.com/firebasejs/11.0.2/firebase-app.js";
import {
  getFirestore, doc, getDoc, setDoc, updateDoc, deleteDoc, increment,
  collection, addDoc, query, where, orderBy, onSnapshot, serverTimestamp
} from "https://www.gstatic.com/firebasejs/11.0.2/firebase-firestore.js";
import {
  getAuth, GoogleAuthProvider, signInWithPopup, signInWithCredential, signOut, onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/11.0.2/firebase-auth.js";

const firebaseConfig = {
  apiKey: "AIzaSyB316NYFmTC9LV1TqPevqjBhRueAybKoH8",
  authDomain: "pelicanlife-blog.firebaseapp.com",
  projectId: "pelicanlife-blog",
  storageBucket: "pelicanlife-blog.firebasestorage.app",
  messagingSenderId: "344172243209",
  appId: "1:344172243209:web:8e4e1a524dd56b3b470bd8",
  measurementId: "G-CX6FM0PQGM"
};
const GOOGLE_CLIENT_ID = "344172243209-k7vmhdpsg4h8ihegbndit802o1qu6knk.apps.googleusercontent.com";

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const auth = getAuth(app);

let currentUser = null;
let openReplyFor = null;   // 인라인 답글 입력창이 열린 최상위 댓글 id
let lastItems = [];        // 마지막 스냅샷 (답글창 토글 시 재렌더용)

onAuthStateChanged(auth, (user) => {
  currentUser = user;
  renderNavbar(user);
  updateCommentPlaceholder(user);
});

initNavbarInteractions();

const reactionsRoot = document.querySelector(".reactions");
const slug = reactionsRoot ? reactionsRoot.dataset.slug : null;
if (slug) {
  initVotes(slug);
  initComments(slug);
}

function likeKeyId(s) {
  return s.replace(/^\/|\/$/g, "").replace(/\//g, "_") || "root";
}

// ---------- Navbar avatar ----------
function renderNavbar(user) {
  let el = document.getElementById("navbar-auth");
  if (!el) {
    const bar = document.querySelector(".hextra-max-navbar-width");
    if (!bar) return;
    el = document.createElement("div");
    el.id = "navbar-auth";
    el.className = "navbar-auth";
    bar.appendChild(el);
  }
  if (user) {
    el.innerHTML =
      '<button class="navbar-avatar-btn" type="button" aria-label="계정 메뉴">' +
        '<img class="navbar-avatar" src="' + escAttr(user.photoURL || "") + '" alt="" referrerpolicy="no-referrer">' +
      "</button>" +
      '<div class="navbar-menu" hidden>' +
        '<div class="navbar-name">' + esc(user.displayName || "익명") + "</div>" +
        '<button class="navbar-logout" type="button">로그아웃</button>' +
      "</div>";
    el.hidden = false;
  } else {
    el.innerHTML = "";
    el.hidden = true;
  }
}

function initNavbarInteractions() {
  document.addEventListener("click", (e) => {
    const el = document.getElementById("navbar-auth");
    if (!el) return;
    if (e.target.closest(".navbar-avatar-btn")) {
      const menu = el.querySelector(".navbar-menu");
      if (menu) menu.hidden = !menu.hidden;
    } else if (e.target.closest(".navbar-logout")) {
      if (window.google && google.accounts && google.accounts.id) google.accounts.id.disableAutoSelect();
      signOut(auth);
    } else if (!e.target.closest("#navbar-auth")) {
      const menu = el.querySelector(".navbar-menu");
      if (menu) menu.hidden = true;
    }
  });
}

function updateCommentPlaceholder(user) {
  const input = document.getElementById("comment-input");
  if (input) input.placeholder = user ? "댓글을 남겨보세요" : "댓글을 남기려면 입력창을 클릭해 Google 로그인";
}

// ---------- Votes (좋아요/싫어요, 배타 토글. 좋아요만 카운트 표시) ----------
function initVotes(slug) {
  const likeBtn = document.getElementById("like-btn");
  const dislikeBtn = document.getElementById("dislike-btn");
  const countEl = document.getElementById("like-count");
  const ref = doc(db, "likes", likeKeyId(slug));
  const lsKey = "reaction:" + slug;   // "like" | "dislike" | (없음)

  function paint(reaction) {
    likeBtn.classList.toggle("active", reaction === "like");
    dislikeBtn.classList.toggle("active", reaction === "dislike");
    likeBtn.setAttribute("aria-pressed", reaction === "like" ? "true" : "false");
    dislikeBtn.setAttribute("aria-pressed", reaction === "dislike" ? "true" : "false");
  }

  onSnapshot(ref, (snap) => {
    const d = snap.exists() ? snap.data() : {};
    countEl.textContent = d.likes || 0;   // 좋아요만 표시 (싫어요는 저장만, 화면 비표시)
  });

  paint(localStorage.getItem(lsKey));

  async function vote(target) {
    const cur = localStorage.getItem(lsKey);
    const next = (cur === target) ? null : target;   // 같은 버튼 재클릭 = 해제
    const likeDelta = (next === "like" ? 1 : 0) - (cur === "like" ? 1 : 0);
    const dislikeDelta = (next === "dislike" ? 1 : 0) - (cur === "dislike" ? 1 : 0);
    try {
      await setDoc(ref, { likes: increment(likeDelta), dislikes: increment(dislikeDelta) }, { merge: true });
      if (next) localStorage.setItem(lsKey, next);
      else localStorage.removeItem(lsKey);
      paint(next);
    } catch (e) {
      console.error("vote failed", e);
    }
  }

  likeBtn.addEventListener("click", () => vote("like"));
  dislikeBtn.addEventListener("click", () => vote("dislike"));
}

// ---------- Comments (inline replies) ----------
function initComments(slug) {
  const form = document.getElementById("comment-form");
  const input = document.getElementById("comment-input");
  const listEl = document.getElementById("comment-list");
  const totalEl = document.getElementById("comment-total");

  // 최상위 댓글 입력
  input.addEventListener("focus", () => { if (!currentUser) promptLogin(); });
  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    if (!currentUser) { promptLogin(); return; }
    const text = input.value.trim();
    if (!text) return;
    try {
      await postComment(slug, null, text);
      input.value = "";
    } catch (e) {
      console.error("comment failed", e);
    }
  });

  // 목록 영역: 답글 열기/취소/등록, 삭제 (이벤트 위임)
  listEl.addEventListener("click", (e) => {
    const replyBtn = e.target.closest("[data-reply]");
    const cancelBtn = e.target.closest("[data-reply-cancel]");
    const submitBtn = e.target.closest("[data-reply-submit]");
    const delBtn = e.target.closest("[data-del]");

    if (replyBtn) {
      if (!currentUser) { promptLogin(); return; }
      openReplyFor = (openReplyFor === replyBtn.dataset.reply) ? null : replyBtn.dataset.reply;
      renderComments(listEl, lastItems);
      const ta = listEl.querySelector(".reactions-reply-input");
      if (ta) ta.focus();
    } else if (cancelBtn) {
      openReplyFor = null;
      renderComments(listEl, lastItems);
    } else if (submitBtn) {
      const box = submitBtn.closest(".reactions-reply-box");
      const ta = box ? box.querySelector(".reactions-reply-input") : null;
      const text = ta ? ta.value.trim() : "";
      if (!text || !currentUser) return;
      postComment(slug, submitBtn.dataset.replySubmit, text)
        .then(() => { openReplyFor = null; })
        .catch((err) => console.error(err));
    } else if (delBtn && confirm("댓글을 삭제할까요?")) {
      deleteDoc(doc(db, "comments", delBtn.dataset.del)).catch((err) => console.error(err));
    }
  });

  const q = query(collection(db, "comments"), where("slug", "==", slug), orderBy("createdAt", "asc"));
  onSnapshot(q, (snap) => {
    lastItems = [];
    snap.forEach((d) => lastItems.push({ id: d.id, ...d.data() }));
    totalEl.textContent = lastItems.length;
    renderComments(listEl, lastItems);
  });
}

function postComment(slug, parentId, text) {
  return addDoc(collection(db, "comments"), {
    slug,
    parentId: parentId || null,
    authorUid: currentUser.uid,
    authorName: currentUser.displayName || "익명",
    authorPhoto: currentUser.photoURL || "",
    text,
    createdAt: serverTimestamp()
  });
}

function renderComments(listEl, items) {
  const tops = items.filter((c) => !c.parentId);
  const repliesOf = (id) => items.filter((c) => c.parentId === id);
  if (!tops.length) {
    listEl.innerHTML = '<p class="reactions-empty">첫 댓글을 남겨보세요.</p>';
    return;
  }
  listEl.innerHTML = tops
    .map((c) => {
      let html = commentHTML(c, false);
      html += repliesOf(c.id).map((r) => commentHTML(r, true)).join("");
      if (openReplyFor === c.id) html += replyBoxHTML(c.id);
      return html;
    })
    .join("");
}

function commentHTML(c, isReply) {
  const mine = currentUser && currentUser.uid === c.authorUid;
  const when = c.createdAt && c.createdAt.toDate ? fmt(c.createdAt.toDate()) : "";
  return (
    '<div class="reactions-comment' + (isReply ? " is-reply" : "") + '">' +
      '<img class="reactions-avatar" src="' + escAttr(c.authorPhoto || "") + '" alt="" referrerpolicy="no-referrer">' +
      '<div class="reactions-body">' +
        '<div class="reactions-meta"><span class="reactions-author">' + esc(c.authorName) + "</span>" +
          (when ? '<span class="reactions-time">' + when + "</span>" : "") + "</div>" +
        '<div class="reactions-text">' + esc(c.text) + "</div>" +
        '<div class="reactions-actions">' +
          (isReply ? "" : '<button class="reactions-link" data-reply="' + escAttr(c.id) + '">답글</button>') +
          (mine ? '<button class="reactions-link" data-del="' + escAttr(c.id) + '">삭제</button>' : "") +
        "</div>" +
      "</div>" +
    "</div>"
  );
}

function replyBoxHTML(parentId) {
  return (
    '<div class="reactions-reply-box">' +
      '<textarea class="reactions-reply-input" rows="2" maxlength="2000" placeholder="답글을 남겨보세요"></textarea>' +
      '<div class="reactions-form-actions">' +
        '<button type="button" class="reactions-btn-ghost" data-reply-cancel>취소</button>' +
        '<button type="button" class="reactions-btn" data-reply-submit="' + escAttr(parentId) + '">답글 등록</button>' +
      "</div>" +
    "</div>"
  );
}

// ---------- Google One Tap (입력창 클릭 시에만, 팝업 fallback) ----------
let gisReady = false;

async function ensureGIS() {
  if (gisReady) return true;
  if (GOOGLE_CLIENT_ID.indexOf("apps.googleusercontent.com") === -1 || GOOGLE_CLIENT_ID.startsWith("REPLACE")) return false;
  await loadGIS();
  if (!(window.google && google.accounts && google.accounts.id)) return false;
  google.accounts.id.initialize({
    client_id: GOOGLE_CLIENT_ID,
    auto_select: true,
    cancel_on_tap_outside: true,
    callback: async (resp) => {
      try {
        await signInWithCredential(auth, GoogleAuthProvider.credential(resp.credential));
      } catch (e) {
        console.error("One Tap sign-in failed", e);
      }
    }
  });
  gisReady = true;
  return true;
}

async function promptLogin() {
  if (currentUser) return;
  if (!(await ensureGIS())) { popupLogin(); return; }
  google.accounts.id.prompt((n) => {
    try {
      // One Tap 이 '표시조차 안 될 때'(미지원/쿨다운)만 팝업으로 폴백.
      // 사용자가 칩을 닫거나 무시한 경우(skip/dismiss)에는 팝업을 띄우지 않는다.
      if (n.isNotDisplayed && n.isNotDisplayed()) popupLogin();
    } catch (_) { /* noop */ }
  });
}

function popupLogin() {
  signInWithPopup(auth, new GoogleAuthProvider()).catch((e) => console.error(e));
}

function loadGIS() {
  return new Promise((resolve) => {
    if (window.google && google.accounts && google.accounts.id) return resolve();
    const s = document.createElement("script");
    s.src = "https://accounts.google.com/gsi/client";
    s.async = true;
    s.onload = () => resolve();
    s.onerror = () => resolve();
    document.head.appendChild(s);
  });
}

function esc(s) {
  return (s || "").replace(/[&<>"']/g, (m) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[m]));
}
function escAttr(s) { return esc(s); }
function fmt(d) {
  const p = (n) => String(n).padStart(2, "0");
  return d.getFullYear() + "." + p(d.getMonth() + 1) + "." + p(d.getDate()) + " " + p(d.getHours()) + ":" + p(d.getMinutes());
}
