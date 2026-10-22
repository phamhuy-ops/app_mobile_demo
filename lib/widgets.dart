import 'package:flutter/material.dart';

import 'models.dart';
import 'services.dart';
import 'theme.dart';

class StationAvatar extends StatelessWidget {
  const StationAvatar({super.key, this.open = true, this.size = 44});
  final bool open;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xffe4eef5),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(Icons.shield_outlined, color: navy, size: size * 0.48),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.station});
  final Station station;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: station.open ? const Color(0xffdff6ea) : const Color(0xfffff1d6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      station.status,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
        color: station.open ? const Color(0xff147a52) : const Color(0xff9a5d00),
      ),
    ),
  );
}

class UserMarker extends StatelessWidget {
  const UserMarker({super.key});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: signal,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 4),
      boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 8)],
    ),
    child: const Icon(Icons.person, color: Colors.white, size: 20),
  );
}

class StationMarker extends StatelessWidget {
  const StationMarker({super.key, required this.selected, required this.open});
  final bool selected;
  final bool open;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    decoration: BoxDecoration(
      color: selected ? signal : navy,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: selected ? 4 : 3),
      boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6)],
    ),
    child: Icon(
      selected ? Icons.location_on_outlined : Icons.shield_outlined,
      color: Colors.white,
      size: selected ? 22 : 20,
    ),
  );
}

class StationCard extends StatelessWidget {
  const StationCard({
    super.key,
    required this.station,
    required this.distance,
    required this.favorite,
    required this.onDirections,
    required this.onCall,
    required this.onToggleFavorite,
    required this.onOpen,
  });

  final Station station;
  final double distance;
  final bool favorite;
  final VoidCallback onDirections;
  final VoidCallback onCall;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StationAvatar(open: station.open),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: ink,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StatusChip(station: station),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onToggleFavorite,
                    icon: Icon(
                      favorite ? Icons.star : Icons.star_border,
                      color: favorite ? gold : muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: mist,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${formatDistance(distance)}  ·  ${station.hours}',
                  style: const TextStyle(
                    color: navyMid,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                station.address,
                style: const TextStyle(color: muted, height: 1.35),
              ),
              Text(
                formatPhone(station.phone),
                style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCall,
                      icon: const Icon(Icons.call_outlined, size: 18),
                      label: const Text('Gọi'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onDirections,
                      icon: const Icon(Icons.near_me, size: 18),
                      label: const Text('Chỉ đường'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: mist,
            child: Icon(icon, color: navy),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, color: ink),
          ),
          subtitle: Text(value),
          trailing:
              trailing ??
              (onTap == null
                  ? null
                  : const Icon(Icons.chevron_right, color: muted)),
        ),
      ),
    );
  }
}
