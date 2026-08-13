import 'package:flutter/material.dart';
import 'package:project/helper/utils/generalImports.dart';
import 'package:project/provider/themeProvider.dart' as app_theme;

// Shimmer Widgets for Profile Screen
class ProfileInfoShimmer extends StatefulWidget {
  const ProfileInfoShimmer({Key? key}) : super(key: key);

  @override
  State<ProfileInfoShimmer> createState() => _ProfileInfoShimmerState();
}

class _ProfileInfoShimmerState extends State<ProfileInfoShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final isDark = colorScheme == app_theme.AppColorScheme.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.border, width: 1),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: isDark
                              ? const [
                                  Color(0xFF374151),
                                  Color(0xFF4B5563),
                                  Color(0xFF374151),
                                ]
                              : const [
                                  Color(0xFFE0E0E0),
                                  Color(0xFFF5F5F5),
                                  Color(0xFFE0E0E0),
                                ],
                          stops: [
                            _animation.value - 0.3,
                            _animation.value,
                            _animation.value + 0.3,
                          ].map((e) => e.clamp(0.0, 1.0)).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 18,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: isDark
                                    ? const [
                                        Color(0xFF374151),
                                        Color(0xFF4B5563),
                                        Color(0xFF374151),
                                      ]
                                    : const [
                                        Color(0xFFE0E0E0),
                                        Color(0xFFF5F5F5),
                                        Color(0xFFE0E0E0),
                                      ],
                                stops: [
                                  _animation.value - 0.3,
                                  _animation.value,
                                  _animation.value + 0.3,
                                ].map((e) => e.clamp(0.0, 1.0)).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            width: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: isDark
                                    ? const [
                                        Color(0xFF374151),
                                        Color(0xFF4B5563),
                                        Color(0xFF374151),
                                      ]
                                    : const [
                                        Color(0xFFE0E0E0),
                                        Color(0xFFF5F5F5),
                                        Color(0xFFE0E0E0),
                                      ],
                                stops: [
                                  _animation.value - 0.3,
                                  _animation.value,
                                  _animation.value + 0.3,
                                ].map((e) => e.clamp(0.0, 1.0)).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 14,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: isDark
                                  ? const [
                                      Color(0xFF374151),
                                      Color(0xFF4B5563),
                                      Color(0xFF374151),
                                    ]
                                  : const [
                                      Color(0xFFE0E0E0),
                                      Color(0xFFF5F5F5),
                                      Color(0xFFE0E0E0),
                                    ],
                              stops: [
                                _animation.value - 0.3,
                                _animation.value,
                                _animation.value + 0.3,
                              ].map((e) => e.clamp(0.0, 1.0)).toList(),
                            ),
                          ),
                        ),
                        Container(
                          height: 28,
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: isDark
                                  ? const [
                                      Color(0xFF374151),
                                      Color(0xFF4B5563),
                                      Color(0xFF374151),
                                    ]
                                  : const [
                                      Color(0xFFE0E0E0),
                                      Color(0xFFF5F5F5),
                                      Color(0xFFE0E0E0),
                                    ],
                              stops: [
                                _animation.value - 0.3,
                                _animation.value,
                                _animation.value + 0.3,
                              ].map((e) => e.clamp(0.0, 1.0)).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ActionTileShimmer extends StatefulWidget {
  const ActionTileShimmer({Key? key}) : super(key: key);

  @override
  State<ActionTileShimmer> createState() => _ActionTileShimmerState();
}

class _ActionTileShimmerState extends State<ActionTileShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final isDark = colorScheme == app_theme.AppColorScheme.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 90,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.border, width: 1),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: isDark
                        ? const [
                            Color(0xFF374151),
                            Color(0xFF4B5563),
                            Color(0xFF374151),
                          ]
                        : const [
                            Color(0xFFE0E0E0),
                            Color(0xFFF5F5F5),
                            Color(0xFFE0E0E0),
                          ],
                    stops: [
                      _animation.value - 0.3,
                      _animation.value,
                      _animation.value + 0.3,
                    ].map((e) => e.clamp(0.0, 1.0)).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: isDark
                              ? const [
                                  Color(0xFF374151),
                                  Color(0xFF4B5563),
                                  Color(0xFF374151),
                                ]
                              : const [
                                  Color(0xFFE0E0E0),
                                  Color(0xFFF5F5F5),
                                  Color(0xFFE0E0E0),
                                ],
                          stops: [
                            _animation.value - 0.3,
                            _animation.value,
                            _animation.value + 0.3,
                          ].map((e) => e.clamp(0.0, 1.0)).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: isDark
                              ? const [
                                  Color(0xFF374151),
                                  Color(0xFF4B5563),
                                  Color(0xFF374151),
                                ]
                              : const [
                                  Color(0xFFE0E0E0),
                                  Color(0xFFF5F5F5),
                                  Color(0xFFE0E0E0),
                                ],
                          stops: [
                            _animation.value - 0.3,
                            _animation.value,
                            _animation.value + 0.3,
                          ].map((e) => e.clamp(0.0, 1.0)).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ActionTileLargeShimmer extends StatefulWidget {
  const ActionTileLargeShimmer({Key? key}) : super(key: key);

  @override
  State<ActionTileLargeShimmer> createState() => _ActionTileLargeShimmerState();
}

class _ActionTileLargeShimmerState extends State<ActionTileLargeShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final isDark = colorScheme == app_theme.AppColorScheme.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 192,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.border, width: 1),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: isDark
                        ? const [
                            Color(0xFF374151),
                            Color(0xFF4B5563),
                            Color(0xFF374151),
                          ]
                        : const [
                            Color(0xFFE0E0E0),
                            Color(0xFFF5F5F5),
                            Color(0xFFE0E0E0),
                          ],
                    stops: [
                      _animation.value - 0.3,
                      _animation.value,
                      _animation.value + 0.3,
                    ].map((e) => e.clamp(0.0, 1.0)).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 16,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: isDark
                        ? const [
                            Color(0xFF374151),
                            Color(0xFF4B5563),
                            Color(0xFF374151),
                          ]
                        : const [
                            Color(0xFFE0E0E0),
                            Color(0xFFF5F5F5),
                            Color(0xFFE0E0E0),
                          ],
                    stops: [
                      _animation.value - 0.3,
                      _animation.value,
                      _animation.value + 0.3,
                    ].map((e) => e.clamp(0.0, 1.0)).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: isDark
                        ? const [
                            Color(0xFF374151),
                            Color(0xFF4B5563),
                            Color(0xFF374151),
                          ]
                        : const [
                            Color(0xFFE0E0E0),
                            Color(0xFFF5F5F5),
                            Color(0xFFE0E0E0),
                          ],
                    stops: [
                      _animation.value - 0.3,
                      _animation.value,
                      _animation.value + 0.3,
                    ].map((e) => e.clamp(0.0, 1.0)).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 24,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: isDark
                        ? const [
                            Color(0xFF374151),
                            Color(0xFF4B5563),
                            Color(0xFF374151),
                          ]
                        : const [
                            Color(0xFFE0E0E0),
                            Color(0xFFF5F5F5),
                            Color(0xFFE0E0E0),
                          ],
                    stops: [
                      _animation.value - 0.3,
                      _animation.value,
                      _animation.value + 0.3,
                    ].map((e) => e.clamp(0.0, 1.0)).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MenuShimmer extends StatefulWidget {
  const MenuShimmer({Key? key}) : super(key: key);

  @override
  State<MenuShimmer> createState() => _MenuShimmerState();
}

class _MenuShimmerState extends State<MenuShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<app_theme.ThemeProvider>();
    final colorScheme = themeProvider.colorScheme;
    final isDark = colorScheme == app_theme.AppColorScheme.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.border, width: 1),
            boxShadow: colorScheme.cardShadow,
          ),
          child: Column(
            children: List.generate(8, (index) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: isDark
                                  ? const [
                                      Color(0xFF374151),
                                      Color(0xFF4B5563),
                                      Color(0xFF374151),
                                    ]
                                  : const [
                                      Color(0xFFE0E0E0),
                                      Color(0xFFF5F5F5),
                                      Color(0xFFE0E0E0),
                                    ],
                              stops: [
                                _animation.value - 0.3,
                                _animation.value,
                                _animation.value + 0.3,
                              ].map((e) => e.clamp(0.0, 1.0)).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: isDark
                                    ? const [
                                        Color(0xFF374151),
                                        Color(0xFF4B5563),
                                        Color(0xFF374151),
                                      ]
                                    : const [
                                        Color(0xFFE0E0E0),
                                        Color(0xFFF5F5F5),
                                        Color(0xFFE0E0E0),
                                      ],
                                stops: [
                                  _animation.value - 0.3,
                                  _animation.value,
                                  _animation.value + 0.3,
                                ].map((e) => e.clamp(0.0, 1.0)).toList(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: isDark
                                  ? const [
                                      Color(0xFF374151),
                                      Color(0xFF4B5563),
                                      Color(0xFF374151),
                                    ]
                                  : const [
                                      Color(0xFFE0E0E0),
                                      Color(0xFFF5F5F5),
                                      Color(0xFFE0E0E0),
                                    ],
                              stops: [
                                _animation.value - 0.3,
                                _animation.value,
                                _animation.value + 0.3,
                              ].map((e) => e.clamp(0.0, 1.0)).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < 7)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: colorScheme.divider,
                    ),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}
