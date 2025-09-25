import 'package:flutter/material.dart';

/// Common UI definitions used across the application.

// Colour palette.  These constants are used throughout the pages
// for cards, borders, muted text and accent highlights.
const Color card = Color(0xFF1E293B);
const Color border = Color(0xFF334155);
const Color muted = Color(0xFF64748B);
const Color accent = Color(0xFF38BDF8);

/// A simple tile widget used to display a label and value pair.  When
/// [full] is true the tile expands to take up the available width.
class Tile extends StatelessWidget {
  final String label;
  final Widget value;
  final bool full;
  const Tile({super.key, required this.label, required this.value, this.full = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: full ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 4),
          value,
        ],
      ),
    );
  }
}

/// A badge chip used to display external links or social handles.
class BadgeChip extends StatelessWidget {
  final Widget child;
  const BadgeChip({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: border,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

/// A simple navigation bar used throughout the application.  It
/// implements [PreferredSizeWidget] so it can be used as an `appBar`
/// within a [Scaffold].  Each callback is optional; when supplied the
/// corresponding button is shown.
class NavBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? profile;
  final VoidCallback? money;
  final VoidCallback? wellbeing;
  final VoidCallback? pdf;
  final VoidCallback? share;

  const NavBar({
    super.key,
    this.profile,
    this.money,
    this.wellbeing,
    this.pdf,
    this.share,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF0B1220),
      leading: profile != null
          ? IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: profile,
            )
          : null,
      actions: [
        if (money != null)
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: money,
          ),
        if (wellbeing != null)
          IconButton(
            icon: const Icon(Icons.self_improvement_outlined),
            onPressed: wellbeing,
          ),
        if (pdf != null)
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: pdf,
          ),
        if (share != null)
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: share,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}