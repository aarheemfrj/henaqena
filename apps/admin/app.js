const queue = [
  {type:'تقييم', name:'مريم علي', detail:'تقييم جديد لمركز الشفاء الطبي', initial:'م'},
  {type:'إعلان', name:'محمد أحمد', detail:'شقة للإيجار — قنا الجديدة', initial:'م'},
  {type:'مقدم خدمة', name:'عيادة النور', detail:'طلب إضافة مقدم خدمة · خدمات طبية', initial:'ع'},
];
const item = (row) => `<div class="queue-item"><div class="avatar">${row.initial}</div><div class="meta"><strong>${row.name}</strong><small>${row.type} · ${row.detail}</small></div><div class="actions"><button class="approve" data-toast="تم الاعتماد للمراجعة النهائية">اعتماد</button><button class="reject" data-toast="تم تسجيل الرفض للمراجعة">رفض</button></div></div>`;
document.querySelector('#overview-queue').innerHTML = queue.slice(0,3).map(item).join('');
document.querySelector('#review-queue').innerHTML = queue.concat([{type:'إعلان',name:'سارة حسن',detail:'ثلاجة بحالة ممتازة · 3 صور',initial:'س'}]).map(item).join('');
document.querySelector('#listing-queue').innerHTML = queue.filter((x) => x.type === 'إعلان').map(item).join('');
const toast = document.querySelector('#toast');
document.addEventListener('click', (event) => {
  const view = event.target.closest('[data-view]');
  if (view) {
    document.querySelectorAll('.nav-item').forEach((button) => button.classList.toggle('active', button.dataset.view === view.dataset.view));
    document.querySelectorAll('.view').forEach((section) => section.classList.toggle('active-view', section.id === view.dataset.view));
    document.querySelector('#page-title').textContent = view.textContent.trim();
  }
  const action = event.target.closest('[data-toast]');
  if (action) { toast.textContent = action.dataset.toast; toast.classList.add('show'); setTimeout(() => toast.classList.remove('show'), 2200); }
});
