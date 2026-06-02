import 'package:flutter/material.dart';
import '../models/act.dart';
import '../services/api.dart';
import 'act_detail_screen.dart';

const _categoryLabels = {
  'tree_mangrove': 'Tree / Mangrove',
  'wildlife': 'Wildlife',
  'recycling': 'Recycling',
  'litter_cleanup': 'Litter Cleanup',
};

class ActsScreen extends StatefulWidget {
  const ActsScreen({super.key});

  @override
  State<ActsScreen> createState() => _ActsScreenState();
}

class _ActsScreenState extends State<ActsScreen> {
  List<Act> _acts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final acts = await getActs();
      if (mounted) setState(() => _acts = acts);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('My Acts'), backgroundColor: Colors.white),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF22c55e)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : _acts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco_outlined, size: 56, color: Color(0xFFd1d5db)),
                          SizedBox(height: 12),
                          Text('No acts yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Log your first act!', style: TextStyle(color: Color(0xFFd1d5db), fontSize: 13)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFF22c55e),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _acts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
                        itemBuilder: (context, i) => _ActTile(act: _acts[i]),
                      ),
                    ),
    );
  }
}

class _ActTile extends StatelessWidget {
  final Act act;
  const _ActTile({required this.act});

  @override
  Widget build(BuildContext context) {
    final label = _categoryLabels[act.category] ?? act.category;
    final date = act.createdAt.toLocal();
    final dateStr = '${date.day} ${_month(date.month)} ${date.year}';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      isThreeLine: act.description.isNotEmpty,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: act.photoUrl.isNotEmpty
            ? Image.network(
                act.photoUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          if (act.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              act.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ActDetailScreen(act: act)),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 56,
        height: 56,
        color: const Color(0xFFf0f0f0),
        child: const Icon(Icons.image_outlined, color: Color(0xFFcccccc)),
      );

  String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}
