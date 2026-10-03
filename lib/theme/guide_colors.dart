import 'package:flutter/material.dart';

/// The same guide keeps its accent in the list and on its detail screen.
({Color foreground, Color background}) guideColors(IconData icon) =>
    switch (icon) {
      Icons.water_drop_outlined => (
        foreground: const Color(0xFF176398),
        background: const Color(0xFFE3F2FD),
      ),
      Icons.air => (
        foreground: const Color(0xFF006D77),
        background: const Color(0xFFDDF4F3),
      ),
      Icons.accessibility_new => (
        foreground: const Color(0xFF995015),
        background: const Color(0xFFFFEEDD),
      ),
      Icons.psychology_outlined => (
        foreground: const Color(0xFF744299),
        background: const Color(0xFFF2E7FA),
      ),
      Icons.self_improvement => (
        foreground: const Color(0xFF9A3C70),
        background: const Color(0xFFFBE6F0),
      ),
      Icons.directions_walk => (
        foreground: const Color(0xFF397126),
        background: const Color(0xFFEAF4DF),
      ),
      Icons.bedtime_outlined => (
        foreground: const Color(0xFF444F9A),
        background: const Color(0xFFEBEDFC),
      ),
      _ => (
        foreground: const Color(0xFFA33636),
        background: const Color(0xFFFCE8E5),
      ),
    };
