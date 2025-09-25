import 'package:flutter/material.dart';

/// A simple navigation bar used throughout the example application.
///
/// The bar exposes five optional callbacks: [profile], [money],
/// [wellbeing], [pdf] and [share].  If a callback is provided, its
/// corresponding icon button is shown; otherwise the button is omitted.
/// The bar itself behaves like an [AppBar] and implements the
/// [PreferredSizeWidget] interface so it can be used in the `appBar`
/// property of a [Scaffold].
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
      title: const Text(''),
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