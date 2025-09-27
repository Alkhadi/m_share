/* --- NAV ACTIVE STATE --- */
(function () {
  const path = (location.pathname.split('/').pop() || 'index.html').toLowerCase();
  document.querySelectorAll('nav a').forEach(a => {
    const href = (a.getAttribute('href') || '').toLowerCase();
    if (href === path) a.classList.add('active');
  });
})();

/* --- STRIPE CHECKOUT REDIRECT --- */
window.STRIPE_SERVER_ORIGIN = window.STRIPE_SERVER_ORIGIN ||
  (location.hostname === 'localhost' ? 'http://localhost:4242' : location.origin);

/* Click any element with data-price-id to start Stripe Checkout */
document.addEventListener('click', async (e) => {
  const btn = e.target.closest('[data-price-id]');
  if (!btn) return;

  e.preventDefault();
  const priceId = btn.dataset.priceId;
  if (!priceId) return;

  btn.disabled = true;
  const original = btn.textContent;
  btn.textContent = 'Redirecting…';

  try {
    const res = await fetch(`${window.STRIPE_SERVER_ORIGIN}/create-checkout-session`, {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({ priceId })
    });
    const data = await res.json();
    if (data && data.url) {
      location.href = data.url;
    } else {
      alert(data?.error || 'Unable to start checkout');
    }
  } catch (err) {
    console.error(err);
    alert('Network error starting checkout.');
  } finally {
    btn.disabled = false;
    btn.textContent = original;
  }
});
