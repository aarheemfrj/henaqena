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
const hydrateDashboard = async () => {
  try {
    const [overview, reviews, listings] = await Promise.all([getJson('/api/admin/overview'), getJson('/api/admin/reviews?status=PENDING'), getJson('/api/admin/listings')]);
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
hydrateDashboard();
document.addEventListener('click', (event) => {
  const view = event.target.closest('[data-view]');
  if (view) {
    document.querySelectorAll('.nav-item').forEach((button) => button.classList.toggle('active', button.dataset.view === view.dataset.view));
    document.querySelectorAll('.view').forEach((section) => section.classList.toggle('active-view', section.id === view.dataset.view));
    document.querySelector('#page-title').textContent = view.textContent.trim();
  }
  const action = event.target.closest('[data-toast]');
  if (action) { showToast(action.dataset.toast); }
});
