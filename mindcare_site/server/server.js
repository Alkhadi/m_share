require('dotenv').config();
const express = require('express');
const cors = require('cors');
const Stripe = require('stripe');

const app = express();
const stripe = Stripe(process.env.STRIPE_SECRET_KEY);

app.use(cors({ origin: true }));
app.use(express.json());

app.get('/', (_, res) => res.json({ ok: true }));

app.post('/create-checkout-session', async (req, res) => {
  try {
    const { priceId, mode } = req.body || {};
    if (!priceId) return res.status(400).json({ error: 'Missing priceId' });

    // Where to send the user back after checkout
    const origin = process.env.CLIENT_URL || req.headers.origin || 'http://localhost:5500';

    const session = await stripe.checkout.sessions.create({
      // Use 'subscription' if your Price is recurring; 'payment' for one‑time
      mode: mode || 'payment',
      line_items: [{ price: priceId, quantity: 1 }],
      allow_promotion_codes: true,
      automatic_tax: { enabled: true },
      success_url: `${origin}/success.html?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${origin}/cancel.html`,
    });
    res.json({ url: session.url });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

const port = process.env.PORT || 4242;
app.listen(port, () => console.log(`Stripe server listening on :${port}`));
