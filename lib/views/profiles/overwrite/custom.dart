part of 'overwrite.dart';

class _CustomContent extends ConsumerWidget {
  const _CustomContent();

  void _handleUseDefault(WidgetRef ref, int profileId) async {
    final clashConfig = await ref.read(clashConfigProvider(profileId).future);
    await database.setProfileCustomData(
      profileId,
      clashConfig.proxyGroups,
      clashConfig.rules,
    );
  }

  void _handleToProxyGroupsView(BuildContext context, int profileId) {
    BaseNavigator.push(context, _CustomProxyGroupsView(profileId));
  }

  void _handleToRulesView(BuildContext context, int profileId) {
    BaseNavigator.push(context, _CustomRulesView(profileId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileId = ProfileIdProvider.of(context)!.profileId;
    final proxyGroupNum =
        ref.watch(proxyGroupsCountProvider(profileId)).value ?? -1;
    final ruleNum = ref.watch(customRulesCountProvider(profileId)).value ?? -1;
    final hasDefault = ref.watch(
      clashConfigProvider(profileId).select((state) {
        final clashConfig = state.value;
        return ((clashConfig?.proxyGroups.length ?? 0) +
                (clashConfig?.rules.length ?? 0)) >
            0;
      }),
    );
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: Column(
            children: [InfoHeader(info: Info(label: '自定义'))],
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: _MoreActionButton(
            label: '策略组',
            onPressed: () {
              _handleToProxyGroupsView(context, profileId);
            },
            trailing: Card.filled(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: BoxConstraints(minWidth: 44),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(
                    textAlign: TextAlign.center,
                    '$proxyGroupNum',
                    style: context.textTheme.bodySmall,
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 4)),
        SliverToBoxAdapter(
          child: _MoreActionButton(
            label: '规则',
            onPressed: () {
              _handleToRulesView(context, profileId);
            },
            trailing: Card.filled(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: BoxConstraints(minWidth: 44),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  '$ruleNum',
                  style: context.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 32)),
        if (proxyGroupNum == 0 && ruleNum == 0 && hasDefault)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: MaterialBanner(
                elevation: 0,
                dividerColor: Colors.transparent,
                content: Text('检测到没有数据'),
                actions: [
                  CommonMinFilledButtonTheme(
                    child: FilledButton.tonal(
                      onPressed: () {
                        _handleUseDefault(ref, profileId);
                      },
                      child: Text('一键填入'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
