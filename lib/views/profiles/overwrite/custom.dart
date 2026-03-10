part of 'overwrite.dart';

class _CustomContent extends ConsumerWidget {
  final int profileId;

  const _CustomContent(this.profileId);

  void _handleUseDefault() async {
    final configMap = await coreController.getConfig(profileId);
    final clashConfig = ClashConfig.fromJson(configMap);
    await database.setProfileCustomData(
      profileId,
      clashConfig.proxyGroups,
      clashConfig.rules,
    );
  }

  void _handleToProxyGroupsView(BuildContext context) {
    BaseNavigator.push(context, _CustomProxyGroupsView(profileId));
  }

  void _handleToRulesView(BuildContext context) {
    BaseNavigator.push(context, _CustomRulesView(profileId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proxyGroupNum =
        ref.watch(proxyGroupsCountProvider(profileId)).value ?? -1;
    final ruleNum = ref.watch(customRulesCountProvider(profileId)).value ?? -1;
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
            label: '代理组',
            onPressed: () {
              _handleToProxyGroupsView(context);
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
              _handleToRulesView(context);
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
        if (proxyGroupNum == 0 && ruleNum == 0)
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
                      onPressed: _handleUseDefault,
                      child: Text('一键填入'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // SliverToBoxAdapter(child: SizedBox(height: 8)),
        // SliverToBoxAdapter(
        //   child: Padding(
        //     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        //     child: CommonCard(
        //       radius: 18,
        //       child: ListTile(
        //         minTileHeight: 0,
        //         minVerticalPadding: 0,
        //         titleTextStyle: context.textTheme.bodyMedium?.toJetBrainsMono,
        //         contentPadding: const EdgeInsets.symmetric(
        //           horizontal: 16,
        //           vertical: 16,
        //         ),
        //         title: Row(
        //           crossAxisAlignment: CrossAxisAlignment.center,
        //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //           children: [
        //             Flexible(
        //               child: Text('自定义规则', style: context.textTheme.bodyLarge),
        //             ),
        //             Icon(Icons.arrow_forward_ios, size: 18),
        //           ],
        //         ),
        //       ),
        //       onPressed: () {},
        //     ),
        //   ),
        // ),
      ],
    );
  }
}

class _CustomProxyGroupsView extends ConsumerWidget {
  final int profileId;

  const _CustomProxyGroupsView(this.profileId);

  void _handleReorder(WidgetRef ref, int oldIndex, int newIndex) {
    ref.read(proxyGroupsProvider(profileId).notifier).order(oldIndex, newIndex);
  }

  void _handleEditProxyGroup(BuildContext context, ProxyGroup proxyGroup) {
    showSheet(
      context: context,
      props: SheetProps(
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        maxWidth: 400,
      ),
      builder: (context) {
        return _EditCustomProxyGroupNestedSheet(proxyGroup);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proxyGroups = ref.watch(proxyGroupsProvider(profileId)).value ?? [];
    return CommonScaffold(
      title: '代理组',
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        padding: EdgeInsets.only(bottom: 16),
        itemBuilder: (_, index) {
          final proxyGroup = proxyGroups[index];
          return ReorderableDelayedDragStartListener(
            key: ValueKey(proxyGroup),
            index: index,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: CommonCard(
                radius: 16,
                padding: EdgeInsets.all(16),
                onPressed: () {
                  _handleEditProxyGroup(context, proxyGroup);
                },
                child: ListTile(
                  minTileHeight: 0,
                  minVerticalPadding: 0,
                  titleTextStyle: context.textTheme.bodyMedium?.toJetBrainsMono,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  title: Text(proxyGroup.name),
                  subtitle: Text(proxyGroup.type.name),
                ),
              ),
            ),
          );
        },
        itemCount: proxyGroups.length,
        onReorder: (oldIndex, newIndex) {
          _handleReorder(ref, oldIndex, newIndex);
        },
      ),
    );
  }
}

class _EditCustomProxyGroupNestedSheet extends StatelessWidget {
  final ProxyGroup proxyGroup;

  const _EditCustomProxyGroupNestedSheet(this.proxyGroup);

  Future<void> _handlePop(
    BuildContext context,
    NavigatorState? navigatorState,
  ) async {
    if (navigatorState != null && navigatorState.canPop()) {
      final res = await globalState.showMessage(
        message: TextSpan(text: '确定要退出当前窗口吗?'),
      );
      if (res != true) {
        return;
      }
    }
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<NavigatorState> nestedNavigatorKey = GlobalKey();
    final nestedNavigator = Navigator(
      key: nestedNavigatorKey,
      onGenerateInitialRoutes: (navigator, initialRoute) {
        return [
          PagedSheetRoute(
            builder: (context) {
              return _EditCustomProxyGroupView(proxyGroup);
            },
          ),
        ];
      },
    );
    final sheetProvider = SheetProvider.of(context);
    return CommonPopScope(
      onPop: (_) async {
        _handlePop(context, nestedNavigatorKey.currentState);
        return false;
      },
      child: sheetProvider!.copyWith(
        nestedNavigatorPopCallback: () {
          Navigator.of(context).pop();
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () async {
                  _handlePop(context, nestedNavigatorKey.currentState);
                },
              ),
            ),
            SheetViewport(
              child: PagedSheet(
                decoration: MaterialSheetDecoration(
                  size: SheetSize.stretch,
                  borderRadius: sheetProvider.type == SheetType.bottomSheet
                      ? BorderRadius.vertical(top: Radius.circular(28))
                      : BorderRadius.zero,
                  clipBehavior: Clip.antiAlias,
                ),
                navigator: nestedNavigator,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditCustomProxyGroupView extends ConsumerStatefulWidget {
  final ProxyGroup proxyGroup;

  const _EditCustomProxyGroupView(this.proxyGroup);

  @override
  ConsumerState createState() => _EditCustomProxyGroupViewState();
}

class _EditCustomProxyGroupViewState
    extends ConsumerState<_EditCustomProxyGroupView> {
  final _nameController = TextEditingController();
  final _hideController = ValueNotifier<bool>(false);
  final _disableUDPController = ValueNotifier<bool>(false);
  final _proxiesController = ValueNotifier<List<String>>([]);
  final _useController = ValueNotifier<List<String>>([]);
  final _typeController = ValueNotifier<GroupType>(GroupType.Selector);
  final _allProxiesController = ValueNotifier<bool>(false);
  final _allProviderController = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    final proxyGroup = widget.proxyGroup;
    _nameController.text = proxyGroup.name;
    _hideController.value = proxyGroup.hidden ?? false;
    _disableUDPController.value = proxyGroup.disableUDP ?? false;
    _typeController.value = proxyGroup.type;
    _proxiesController.value = proxyGroup.proxies ?? [];
    _useController.value = proxyGroup.use ?? [];
    if (proxyGroup.includeAll == true) {
      _allProxiesController.value = true;
      _allProviderController.value = true;
    } else {
      _allProxiesController.value = proxyGroup.includeAllProxies ?? false;
      _allProviderController.value = proxyGroup.includeAllProviders ?? false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hideController.dispose();
    _disableUDPController.dispose();
    _typeController.dispose();
    _proxiesController.dispose();
    _useController.dispose();
    _allProxiesController.dispose();
    _allProviderController.dispose();
    super.dispose();
  }

  Future<void> _showTypeOptions() async {
    final value = await globalState.showCommonDialog<GroupType>(
      child: OptionsDialog<GroupType>(
        title: '类型',
        options: GroupType.values,
        textBuilder: (item) => item.name,
        value: _typeController.value,
      ),
    );
    if (value == null) {
      return;
    }
    _typeController.value = value;
  }

  Widget _buildItem({
    required Widget title,
    Widget? trailing,
    final VoidCallback? onPressed,
  }) {
    return CommonInputListItem(
      onPressed: onPressed,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 16,
        children: [
          title,
          if (trailing != null)
            Flexible(
              child: IconTheme(
                data: IconThemeData(
                  size: 16,
                  color: context.colorScheme.onSurface.opacity60,
                ),
                child: Container(
                  alignment: Alignment.centerRight,
                  height: globalState.measure.bodyLargeHeight + 24,
                  child: trailing,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleToProxies() {
    final isBottomSheet =
        SheetProvider.of(context)?.type == SheetType.bottomSheet;
    Navigator.of(context).push(
      PagedSheetRoute(
        builder: (context) => SizedBox(
          height: isBottomSheet
              ? appController.viewSize.height * 0.85
              : double.maxFinite,
          child: AdaptiveSheetScaffold(
            title: '选择代理',
            body: Center(child: Text('123')),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBottomSheet =
        SheetProvider.of(context)?.type == SheetType.bottomSheet;
    return AdaptiveSheetScaffold(
      actions: [IconButtonData(icon: Icons.check, onPressed: () {})],
      body: SizedBox(
        height: isBottomSheet
            ? appController.viewSize.height * 0.65
            : double.maxFinite,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 20),
          children: [
            generateSectionV3(
              title: '通用',
              items: [
                _buildItem(
                  title: Text('名称'),
                  trailing: TextFormField(
                    controller: _nameController,
                    textAlign: TextAlign.end,
                    decoration: InputDecoration.collapsed(
                      border: NoInputBorder(),
                      hintText: '输入代理组名称',
                    ),
                  ),
                ),
                _buildItem(
                  title: Text('类型'),
                  onPressed: () {
                    _showTypeOptions();
                  },
                  trailing: ValueListenableBuilder(
                    valueListenable: _typeController,
                    builder: (_, type, _) {
                      return Text(type.name);
                    },
                  ),
                ),
                _buildItem(title: Text('图标')),
                _buildItem(
                  title: Text('从列表中隐藏'),
                  onPressed: () {
                    _hideController.value = !_hideController.value;
                  },
                  trailing: ValueListenableBuilder(
                    valueListenable: _hideController,
                    builder: (_, value, _) {
                      return Switch(
                        value: value,
                        onChanged: (value) {
                          _hideController.value = value;
                        },
                      );
                    },
                  ),
                ),
                _buildItem(
                  title: Text('禁用UDP'),
                  onPressed: () {
                    _disableUDPController.value = !_disableUDPController.value;
                  },
                  trailing: ValueListenableBuilder(
                    valueListenable: _disableUDPController,
                    builder: (_, value, _) {
                      return Switch(
                        value: value,
                        onChanged: (value) {
                          _disableUDPController.value = value;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            generateSectionV3(
              title: '节点',
              items: [
                _buildItem(
                  title: Text('选择代理'),
                  trailing: ValueListenableBuilder(
                    valueListenable: _proxiesController,
                    builder: (_, proxies, _) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Container(
                              constraints: BoxConstraints(minWidth: 32),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 3,
                                ),
                                child: Text(
                                  textAlign: TextAlign.center,
                                  '${proxies.length}',
                                  style: context.textTheme.bodySmall,
                                ),
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios),
                        ],
                      );
                    },
                  ),
                  onPressed: _handleToProxies,
                ),
                _buildItem(
                  title: Text('选择代理集'),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
                _buildItem(
                  title: Text('节点过滤器'),
                  trailing: TextFormField(
                    textAlign: TextAlign.end,
                    decoration: InputDecoration.collapsed(
                      border: NoInputBorder(),
                      hintText: '可选',
                    ),
                  ),
                ),
                _buildItem(
                  title: Text('排除过滤器'),
                  trailing: TextFormField(
                    textAlign: TextAlign.end,
                    decoration: InputDecoration.collapsed(
                      border: NoInputBorder(),
                      hintText: '可选',
                    ),
                  ),
                ),
                _buildItem(
                  title: Text('排除类型'),
                  trailing: TextFormField(
                    textAlign: TextAlign.end,
                    decoration: InputDecoration.collapsed(
                      border: NoInputBorder(),
                      hintText: '可选',
                    ),
                  ),
                ),
                _buildItem(
                  title: Text('预期状态'),
                  trailing: TextFormField(
                    textAlign: TextAlign.end,
                    decoration: InputDecoration.collapsed(
                      border: NoInputBorder(),
                      hintText: '可选',
                    ),
                  ),
                ),
              ],
            ),
            generateSectionV3(
              title: '其他',
              items: [
                _buildItem(
                  title: Text('测速链接'),
                  trailing: TextFormField(
                    textAlign: TextAlign.end,
                    decoration: InputDecoration.collapsed(
                      border: NoInputBorder(),
                      hintText: '可选',
                    ),
                  ),
                ),
                _buildItem(
                  title: Text('最大失败次数'),
                  trailing: TextFormField(
                    textAlign: TextAlign.end,
                    decoration: InputDecoration.collapsed(
                      border: NoInputBorder(),
                      hintText: '可选',
                    ),
                  ),
                ),
                _buildItem(
                  title: Text('使用时测速'),
                  trailing: Switch(value: false, onChanged: (_) {}),
                ),
                _buildItem(
                  title: Text('测速间隔'),
                  trailing: TextFormField(
                    textAlign: TextAlign.end,
                    decoration: InputDecoration.collapsed(
                      border: NoInputBorder(),
                      hintText: '可选',
                    ),
                  ),
                ),
              ],
            ),
            generateSectionV3(
              title: '操作',
              items: [
                _buildItem(
                  title: Text('删除'),
                  onPressed: () {
                    _disableUDPController.value = !_disableUDPController.value;
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      title: '编辑代理组',
    );
  }
}

class _CustomRulesView extends ConsumerStatefulWidget {
  final int profileId;

  const _CustomRulesView(this.profileId);

  @override
  ConsumerState createState() => _CustomRulesViewState();
}

class _CustomRulesViewState extends ConsumerState<_CustomRulesView> {
  final _key = utils.id;

  void _handleReorder(int oldIndex, int newIndex) {
    ref
        .read(profileCustomRulesProvider(widget.profileId).notifier)
        .order(oldIndex, newIndex);
  }

  void _handleSelected(int ruleId) {
    ref.read(selectedItemsProvider(_key).notifier).update((selectedRules) {
      final newSelectedRules = Set<int>.from(selectedRules)
        ..addOrRemove(ruleId);
      return newSelectedRules;
    });
  }

  void _handleSelectAll() {
    final ids =
        ref
            .read(profileCustomRulesProvider(widget.profileId))
            .value
            ?.map((item) => item.id)
            .toSet() ??
        {};
    ref.read(selectedItemsProvider(_key).notifier).update((selected) {
      return selected.containsAll(ids) ? {} : ids;
    });
  }

  Future<void> _handleDelete() async {
    final res = await globalState.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(
        text: appLocalizations.deleteMultipTip(appLocalizations.rule),
      ),
    );
    if (res != true) {
      return;
    }
    final selectedRules = ref.read(selectedItemsProvider(_key));
    ref
        .read(profileCustomRulesProvider(widget.profileId).notifier)
        .delAll(selectedRules.cast<int>());
    ref.read(selectedItemsProvider(_key).notifier).value = {};
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(context) {
    final rules =
        ref.watch(profileCustomRulesProvider(widget.profileId)).value ?? [];
    final selectedRules = ref.watch(selectedItemsProvider(_key));
    return CommonScaffold(
      title: appLocalizations.rule,
      actions: [
        if (selectedRules.isNotEmpty) ...[
          CommonMinIconButtonTheme(
            child: IconButton.filledTonal(
              onPressed: _handleDelete,
              icon: Icon(Icons.delete),
            ),
          ),
          SizedBox(width: 2),
        ],
        CommonMinFilledButtonTheme(
          child: selectedRules.isNotEmpty
              ? FilledButton(
                  onPressed: _handleSelectAll,
                  child: Text(appLocalizations.selectAll),
                )
              : FilledButton.tonal(
                  onPressed: () {
                    // _handleAddOrUpdate();
                  },
                  child: Text(appLocalizations.add),
                ),
        ),
        SizedBox(width: 8),
      ],
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemBuilder: (_, index) {
          final rule = rules[index];
          return ReorderableDelayedDragStartListener(
            key: ObjectKey(rule),
            index: index,
            child: RuleItem(
              isEditing: selectedRules.isNotEmpty,
              isSelected: selectedRules.contains(rule.id),
              rule: rule,
              onSelected: () {
                _handleSelected(rule.id);
              },
              onEdit: (rule) {
                // _handleAddOrUpdate(rule);
              },
            ),
          );
        },
        itemCount: rules.length,
        onReorder: _handleReorder,
      ),
    );
  }
}
