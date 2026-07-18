const API_BASE = window.HENA_QENA_API || 'http://127.0.0.1:4000';
const ADMIN_KEY = window.HENA_QENA_ADMIN_KEY || localStorage.getItem('henaqena-admin-key') || 'dev-henaqena-admin';
const queue = [];
const item = (row) => `<div class="queue-item"><div class="avatar">${row.initial}</div><div class="meta"><strong>${row.name}</strong><small>${row.type} · ${row.detail}</small></div><div class="actions"><button class="approve" data-toast="تم الاعتماد للمراجعة النهائية">اعتماد</button><button class="reject" data-toast="تم تسجيل الرفض للمراجعة">رفض</button></div></div>`;
document.querySelector('#overview-queue').innerHTML = queue.slice(0,3).map(item).join('');
document.querySelector('#review-queue').innerHTML = queue.concat([{type:'إعلان',name:'سارة حسن',detail:'ثلاجة بحالة ممتازة · 3 صور',initial:'س'}]).map(item).join('');
document.querySelector('#listing-queue').innerHTML = queue.filter((x) => x.type === 'إعلان').map(item).join('');
const toast = document.querySelector('#toast');
const showToast = (message) => { toast.textContent = message; toast.classList.add('show'); setTimeout(() => toast.classList.remove('show'), 2200); };
const getJson = async (path) => { const response = await fetch(`${API_BASE}${path}`, { headers: { 'x-admin-key': ADMIN_KEY } }); if (!response.ok) throw new Error('API'); return response.json(); };
const patchJson = async (path, body) => { const response = await fetch(`${API_BASE}${path}`, { method: 'PATCH', headers: { 'x-admin-key': ADMIN_KEY, 'Content-Type': 'application/json' }, body: JSON.stringify(body || {}) }); if (!response.ok) throw new Error('API'); return response.json(); };

const timeAgo = (isoDate) => {
  const diffSeconds = Math.max(0, Math.floor((Date.now() - new Date(isoDate).getTime()) / 1000));
  if (diffSeconds < 60) return 'الآن';
  const diffMinutes = Math.floor(diffSeconds / 60);
  if (diffMinutes < 60) return `منذ ${diffMinutes} ${diffMinutes === 1 ? 'دقيقة' : 'دقيقة'}`;
  const diffHours = Math.floor(diffMinutes / 60);
  if (diffHours < 24) return `منذ ${diffHours} ${diffHours === 1 ? 'ساعة' : 'ساعة'}`;
  const diffDays = Math.floor(diffHours / 24);
  if (diffDays < 30) return `منذ ${diffDays} ${diffDays === 1 ? 'يوم' : 'يوم'}`;
  return new Date(isoDate).toLocaleDateString('ar-EG');
};

const hydrateDashboard = async () => {
  try {
    const [overview, reviews, listings] = await Promise.all([getJson('/api/admin/overview'), getJson('/api/admin/reviews?unread=true'), getJson('/api/admin/listings')]);
    const stats = document.querySelectorAll('.stats article strong');
    [overview.providers, overview.pending, overview.listings, overview.reviews].forEach((value, index) => { if (stats[index]) stats[index].textContent = Number(value).toLocaleString('ar-EG'); });
    const reviewRows = reviews.map((review) => ({ type: 'تقييم', name: review.author?.name || 'مستخدم', detail: `تقييم جديد لـ ${review.provider?.name || 'مقدم خدمة'}`, initial: (review.author?.name || 'م').slice(0, 1), id: review.id }));
    const listingRows = listings.filter((listing) => listing.status === 'PENDING').map((listing) => ({ type: 'إعلان', name: listing.owner?.name || 'مستخدم', detail: listing.title, initial: (listing.owner?.name || 'م').slice(0, 1), id: listing.id }));
    const rows = reviewRows.concat(listingRows);
    document.querySelector('#overview-queue').innerHTML = rows.slice(0, 3).map(item).join('') || '<p class="empty">لا توجد عناصر معلقة</p>';
    document.querySelector('#review-queue').innerHTML = rows.map(item).join('') || '<p class="empty">لا توجد عناصر معلقة</p>';
    document.querySelector('#listing-queue').innerHTML = listingRows.map(item).join('') || '<p class="empty">لا توجد إعلانات معلقة</p>';
  } catch (_) { showToast('تعذر تحميل بيانات الإدارة'); }
};

// --- نشاط التقييمات: تقييمات وردود جديدة تحتاج مراجعة المشرف ---
let activityItems = [];
let activityFilter = 'all';

const updateActivityBadge = () => {
  const unreadCount = activityItems.filter((entry) => !entry.moderatedAt).length;
  const badge = document.querySelector('#review-activity-badge');
  badge.textContent = unreadCount > 99 ? '99+' : String(unreadCount);
  badge.hidden = unreadCount === 0;
};

const activityRowHtml = (entry) => {
  const author = entry.authorName || 'مستخدم';
  const isUnread = !entry.moderatedAt;
  const typeBadge = entry.kind === 'reply'
    ? '<span class="activity-type-badge reply">رد</span>'
    : '<span class="activity-type-badge review">تقييم</span>';
  const statusBadge = isUnread
    ? '<span class="activity-new-badge">جديد</span>'
    : '<span class="activity-read-badge">✓ تمت المراجعة</span>';
  const markButton = isUnread ? '<button class="activity-mark-btn" data-mark-read>تعليم كمقروء</button>' : '';
  return `<div class="activity-row ${isUnread ? 'unread' : ''}" data-activity-id="${entry.id}" data-activity-kind="${entry.kind}">
    <div class="activity-author"><span class="avatar-dot">${author.slice(0, 1)}</span>${author}</div>
    <div class="activity-target">${entry.targetLabel}${entry.targetSub ? `<small>${entry.targetSub}</small>` : ''}</div>
    <div class="activity-text">${entry.text || '—'}</div>
    <div class="activity-time">${timeAgo(entry.createdAt)}</div>
    <div class="activity-status">${typeBadge}${statusBadge}${markButton}</div>
  </div>`;
};

const renderActivityList = () => {
  const list = document.querySelector('#review-activity-list');
  const filtered = activityFilter === 'unread' ? activityItems.filter((entry) => !entry.moderatedAt) : activityItems;
  list.innerHTML = filtered.map(activityRowHtml).join('') || '<div class="activity-empty">لا توجد تقييمات أو ردود لعرضها</div>';
  updateActivityBadge();
};

const loadReviewActivity = async () => {
  try {
    const [reviews, replies] = await Promise.all([getJson('/api/admin/reviews'), getJson('/api/admin/replies')]);
    const reviewEntries = reviews.map((review) => ({
      id: review.id,
      kind: 'review',
      authorName: review.author?.name,
      targetLabel: review.provider?.name || 'مقدم خدمة',
      targetSub: `تقييم ${review.quality}/${review.commitment}/${review.value}`,
      text: review.comment || 'بدون تعليق مكتوب',
      createdAt: review.createdAt,
      moderatedAt: review.moderatedAt,
    }));
    const replyEntries = replies.map((reply) => ({
      id: reply.id,
      kind: 'reply',
      authorName: reply.author?.name,
      targetLabel: `رد على تقييم ${reply.review?.author?.name || 'مستخدم'}`,
      targetSub: reply.review?.provider?.name || 'مقدم خدمة',
      text: reply.text,
      createdAt: reply.createdAt,
      moderatedAt: reply.moderatedAt,
    }));
    activityItems = reviewEntries.concat(replyEntries).sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    renderActivityList();
  } catch (_) { showToast('تعذر تحميل نشاط التقييمات'); }
};

const markActivityRead = async (id, kind) => {
  const entry = activityItems.find((item) => item.id === id && item.kind === kind);
  if (!entry || entry.moderatedAt) return;
  try {
    const path = kind === 'reply' ? `/api/admin/replies/${id}/read` : `/api/admin/reviews/${id}/read`;
    const updated = await patchJson(path);
    entry.moderatedAt = updated.moderatedAt || new Date().toISOString();
    renderActivityList();
  } catch (_) { showToast('تعذر تحديث الحالة'); }
};

hydrateDashboard();
loadReviewActivity();

document.addEventListener('click', (event) => {
  const view = event.target.closest('[data-view]');
  if (view) {
    document.querySelectorAll('.nav-item').forEach((button) => button.classList.toggle('active', button.dataset.view === view.dataset.view));
    document.querySelectorAll('.view').forEach((section) => section.classList.toggle('active-view', section.id === view.dataset.view));
    const pageTitles = { overview: 'نظرة عامة', 'review-activity': 'نشاط التقييمات', reviews: 'المراجعات', providers: 'مقدمو الخدمات', listings: 'الإعلانات', ads: 'إعلانات الرئيسية', areas: 'المناطق والفئات' };
    document.querySelector('#page-title').textContent = pageTitles[view.dataset.view] || view.dataset.view;
  }

  const activityFilterBtn = event.target.closest('[data-activity-filter]');
  if (activityFilterBtn) {
    activityFilter = activityFilterBtn.dataset.activityFilter;
    document.querySelectorAll('[data-activity-filter]').forEach((button) => button.classList.toggle('active', button === activityFilterBtn));
    renderActivityList();
  }

  const activityRow = event.target.closest('.activity-row');
  if (activityRow) {
    markActivityRead(activityRow.dataset.activityId, activityRow.dataset.activityKind);
  }

  const action = event.target.closest('[data-toast]');
  if (action) { showToast(action.dataset.toast); }
});
