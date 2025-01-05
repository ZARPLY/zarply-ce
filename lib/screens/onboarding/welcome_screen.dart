import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          Stack(
            children: <Widget>[
              // Background curved container (more transparent)
              ClipPath(
                clipper: SteeperCurvedBottomClipper(),
                child: Container(
                  height: MediaQuery.of(context).size.height *
                      0.53, // Slightly bigger
                  color: const Color(0xFF4169E1)
                      .withOpacity(0.3), // More transparent
                ),
              ),
              // Original curved container
              ClipPath(
                clipper: CurvedBottomClipper(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.50,
                  color: const Color(0xFF4169E1),
                  child: const Center(
                    child: SizedBox(
                      width: 300,
                      height: 300,
                      child: Image(
                        image: AssetImage('images/splash.png'),
                        fit: BoxFit.contain,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.2,
                    ),
                    children: <InlineSpan>[
                      TextSpan(text: 'ZARPLY the '),
                      TextSpan(
                        text: 'Rand\nstable-coin\nwallet',
                        style: TextStyle(
                          color: Color(0xFF6B5DE0), // Purple color
                        ),
                      ),
                      TextSpan(text: ' on Solana.'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'When minting ZARP, the system automatically deducts the necessary transaction fees from your wallet balance.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/getting_started'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4169E1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0, size.height * 0.90);

    // Gentler curve overall
    path.quadraticBezierTo(
      size.width * 0.4, // Control point X at center
      size.height * 1.1, // Control point Y just slightly below
      size.width, // End point X
      size.height * 0.85, // End point Y
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class SteeperCurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0, size.height * 0.90);

    // Slightly steeper version of the gentle curve
    path.quadraticBezierTo(
      size.width * 0.45, // Control point X slightly left of center
      size.height * 1.08, // Control point Y slightly lower
      size.width, // End point X
      size.height * 0.90, // End point Y
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
