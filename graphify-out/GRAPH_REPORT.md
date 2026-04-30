# Graph Report - .  (2026-04-29)

## Corpus Check
- 199 files · ~226,487 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1098 nodes · 1453 edges · 84 communities detected
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 12 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 49|Community 49]]
- [[_COMMUNITY_Community 50|Community 50]]
- [[_COMMUNITY_Community 51|Community 51]]
- [[_COMMUNITY_Community 52|Community 52]]
- [[_COMMUNITY_Community 53|Community 53]]
- [[_COMMUNITY_Community 54|Community 54]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]
- [[_COMMUNITY_Community 57|Community 57]]
- [[_COMMUNITY_Community 58|Community 58]]
- [[_COMMUNITY_Community 59|Community 59]]
- [[_COMMUNITY_Community 60|Community 60]]
- [[_COMMUNITY_Community 61|Community 61]]
- [[_COMMUNITY_Community 62|Community 62]]
- [[_COMMUNITY_Community 63|Community 63]]
- [[_COMMUNITY_Community 64|Community 64]]
- [[_COMMUNITY_Community 65|Community 65]]
- [[_COMMUNITY_Community 66|Community 66]]
- [[_COMMUNITY_Community 67|Community 67]]
- [[_COMMUNITY_Community 68|Community 68]]
- [[_COMMUNITY_Community 69|Community 69]]
- [[_COMMUNITY_Community 70|Community 70]]
- [[_COMMUNITY_Community 71|Community 71]]
- [[_COMMUNITY_Community 72|Community 72]]
- [[_COMMUNITY_Community 73|Community 73]]
- [[_COMMUNITY_Community 74|Community 74]]
- [[_COMMUNITY_Community 75|Community 75]]
- [[_COMMUNITY_Community 76|Community 76]]
- [[_COMMUNITY_Community 77|Community 77]]
- [[_COMMUNITY_Community 78|Community 78]]
- [[_COMMUNITY_Community 79|Community 79]]
- [[_COMMUNITY_Community 80|Community 80]]
- [[_COMMUNITY_Community 81|Community 81]]
- [[_COMMUNITY_Community 82|Community 82]]
- [[_COMMUNITY_Community 83|Community 83]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 98 edges
2. `package:liquid_soap_tracker/core/ui/fields/app_text_field.dart` - 43 edges
3. `package:flutter_riverpod/flutter_riverpod.dart` - 40 edges
4. `package:liquid_soap_tracker/core/providers/core_providers.dart` - 34 edges
5. `package:liquid_soap_tracker/core/ui/cards/app_surface_card.dart` - 30 edges
6. `package:liquid_soap_tracker/app/theme/app_colors.dart` - 29 edges
7. `package:liquid_soap_tracker/core/models/app_profile.dart` - 27 edges
8. `package:liquid_soap_tracker/core/utils/formatters.dart` - 26 edges
9. `package:liquid_soap_tracker/core/ui/buttons/primary_button.dart` - 21 edges
10. `package:liquid_soap_tracker/core/ui/layout/reference_page_scaffold.dart` - 15 edges

## Surprising Connections (you probably didn't know these)
- `OnCreate()` --calls--> `RegisterPlugins()`  [INFERRED]
  app/windows/runner/flutter_window.cpp → app/windows/flutter/generated_plugin_registrant.cc
- `OnCreate()` --calls--> `Show()`  [INFERRED]
  app/windows/runner/flutter_window.cpp → app/windows/runner/win32_window.cpp
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  app/windows/runner/main.cpp → app/windows/runner/utils.cpp
- `wWinMain()` --calls--> `SetQuitOnClose()`  [INFERRED]
  app/windows/runner/main.cpp → app/windows/runner/win32_window.cpp
- `main()` --calls--> `my_application_new()`  [INFERRED]
  app/linux/runner/main.cc → app/linux/runner/my_application.cc

## Communities

### Community 0 - "Community 0"
Cohesion: 0.02
Nodes (93): AppColors, AppTextField, build, TextFormField, AppSectionTitle, build, Row, SizedBox (+85 more)

### Community 1 - "Community 1"
Cohesion: 0.02
Nodes (93): AppBootstrap, AppErrorView, AppShell, build, LoginPage, AppSyncBootstrap, _AppSyncBootstrapState, build (+85 more)

### Community 2 - "Community 2"
Cohesion: 0.03
Nodes (85): OfflineSyncService, refreshPendingCount, AuthRepository, _asDouble, attachFinanceOnline, _cacheExpenseOffline, _cacheFinanceOffline, _cachePaymentOffline (+77 more)

### Community 3 - "Community 3"
Cohesion: 0.03
Nodes (79): _ActivityCard, AppSurfaceCard, build, Column, DashboardActivitySection, ListTile, Padding, SizedBox (+71 more)

### Community 4 - "Community 4"
Cohesion: 0.03
Nodes (81): initialize, NotificationDetails, _storePendingTarget, _syncPendingOrderNotifications, TrackerNotificationsService, build, DashboardPage, SizedBox (+73 more)

### Community 5 - "Community 5"
Cohesion: 0.04
Nodes (45): build, Divider, _DrawerTile, _FooterButton, ListTile, Material, SizedBox, TrackerDrawer (+37 more)

### Community 6 - "Community 6"
Cohesion: 0.04
Nodes (38): build, LoginSubmitButton, PrimaryButton, AttachFinanceButton, build, PrimaryButton, build, PrimaryButton (+30 more)

### Community 7 - "Community 7"
Cohesion: 0.04
Nodes (43): AppSurfaceCard, build, dispose, initState, InventoryPage, _InventoryPageState, ListTile, _load (+35 more)

### Community 8 - "Community 8"
Cohesion: 0.05
Nodes (39): AccountPage, _AccountPageState, _AddAccountDialog, _AddAccountDialogState, AlertDialog, AppSurfaceCard, build, dispose (+31 more)

### Community 9 - "Community 9"
Cohesion: 0.05
Nodes (37): LocalStoreService, productBundleKey, _safeWrite, salesDispatchesKey, writeList, writeQueue, AuthContactFooter, build (+29 more)

### Community 10 - "Community 10"
Cohesion: 0.09
Nodes (25): FlutterWindow(), OnCreate(), RegisterPlugins(), wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16(), Create() (+17 more)

### Community 11 - "Community 11"
Cohesion: 0.06
Nodes (31): Align, AppShell, _AppShellState, build, dispose, _goToTab, initState, Scaffold (+23 more)

### Community 12 - "Community 12"
Cohesion: 0.07
Nodes (18): _AddEmployeeDialog, _AddEmployeeDialogState, AlertDialog, build, dispose, EmployeesPage, _EmployeesPageState, initState (+10 more)

### Community 13 - "Community 13"
Cohesion: 0.12
Nodes (16): AddProductSizeDraft, AddProductSizeSheet, _AddProductSizeSheetState, AppSectionTitle, build, dispose, initState, SafeArea (+8 more)

### Community 14 - "Community 14"
Cohesion: 0.12
Nodes (14): AppUuid, hex, v4, Align, AnimatedSplashScreen, _AnimatedSplashScreenState, build, DecoratedBox (+6 more)

### Community 15 - "Community 15"
Cohesion: 0.14
Nodes (13): build, LiquidSoapTrackerApp, MaterialApp, AnimatedSplashScreen, main, ProviderScope, wrapApp, package:flutter_test/flutter_test.dart (+5 more)

### Community 16 - "Community 16"
Cohesion: 0.14
Nodes (13): AppSurfaceCard, build, dispose, initState, ListTile, _load, Padding, ReferenceListPageSkeleton (+5 more)

### Community 17 - "Community 17"
Cohesion: 0.14
Nodes (11): AppErrorView, AppPageScaffold, build, build, SaveExpenseButton, SecondaryButton, build, SecondaryButton (+3 more)

### Community 18 - "Community 18"
Cohesion: 0.29
Nodes (13): api_request(), ensure_project_active(), get_project_status(), log(), main(), ping_postgrest(), Returns the project status string, e.g. 'ACTIVE_HEALTHY', 'INACTIVE'., Attempt to restore a paused project. Returns True on success. (+5 more)

### Community 19 - "Community 19"
Cohesion: 0.17
Nodes (11): build, Container, dispose, _ImageChip, initState, InventoryItemPage, _InventoryItemPageState, SafeArea (+3 more)

### Community 20 - "Community 20"
Cohesion: 0.18
Nodes (8): build, GhostButton, OutlinedButton, SizedBox, build, ElevatedButton, PrimaryButton, SizedBox

### Community 21 - "Community 21"
Cohesion: 0.47
Nodes (9): assert_true(), auth_headers(), create_temp_account(), load_profile(), load_supabase_config(), main(), request_json(), sign_in() (+1 more)

### Community 22 - "Community 22"
Cohesion: 0.22
Nodes (3): AppDelegate, FlutterAppDelegate, FlutterImplicitEngineDelegate

### Community 23 - "Community 23"
Cohesion: 0.22
Nodes (8): AppFormatters, currency, date, dateTime, liters, shortDate, units, package:intl/intl.dart

### Community 24 - "Community 24"
Cohesion: 0.33
Nodes (3): RegisterGeneratedPlugins(), MainFlutterWindow, NSWindow

### Community 25 - "Community 25"
Cohesion: 0.33
Nodes (5): AppIdentity, looksLikePhone, normalizeLoginIdentifier, normalizePhone, phoneToSyntheticEmail

### Community 26 - "Community 26"
Cohesion: 0.4
Nodes (2): RunnerTests, XCTestCase

### Community 27 - "Community 27"
Cohesion: 0.4
Nodes (2): GeneratedPluginRegistrant, -registerWithRegistry

### Community 28 - "Community 28"
Cohesion: 0.5
Nodes (2): FlutterSceneDelegate, SceneDelegate

### Community 29 - "Community 29"
Cohesion: 0.5
Nodes (2): handle_new_rx_page(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.

### Community 30 - "Community 30"
Cohesion: 0.5
Nodes (3): customerName, DisplayCleaner, status

### Community 31 - "Community 31"
Cohesion: 0.5
Nodes (3): ConnectivityService, _isNone, package:connectivity_plus/connectivity_plus.dart

### Community 32 - "Community 32"
Cohesion: 0.5
Nodes (3): copyWith, ProductSetupBundle, ProductSizeSetting

### Community 33 - "Community 33"
Cohesion: 0.83
Nodes (3): bump_build_number(), main(), run()

### Community 34 - "Community 34"
Cohesion: 0.67
Nodes (1): PodsDummy_app_links

### Community 35 - "Community 35"
Cohesion: 0.67
Nodes (1): PodsDummy_connectivity_plus

### Community 36 - "Community 36"
Cohesion: 0.67
Nodes (1): PodsDummy_Pods_Runner

### Community 37 - "Community 37"
Cohesion: 0.67
Nodes (1): PodsDummy_shared_preferences_foundation

### Community 38 - "Community 38"
Cohesion: 0.67
Nodes (1): PodsDummy_Pods_RunnerTests

### Community 39 - "Community 39"
Cohesion: 0.67
Nodes (2): isLikelyOffline, OfflineErrorDetector

### Community 40 - "Community 40"
Cohesion: 0.67
Nodes (0): 

### Community 41 - "Community 41"
Cohesion: 1.0
Nodes (1): PodsDummy_url_launcher_macos

### Community 42 - "Community 42"
Cohesion: 1.0
Nodes (1): PodsDummy_flutter_secure_storage_macos

### Community 43 - "Community 43"
Cohesion: 1.0
Nodes (1): PodsDummy_url_launcher_ios

### Community 44 - "Community 44"
Cohesion: 1.0
Nodes (1): PodsDummy_flutter_secure_storage

### Community 45 - "Community 45"
Cohesion: 1.0
Nodes (1): PodsDummy_flutter_local_notifications

### Community 46 - "Community 46"
Cohesion: 1.0
Nodes (1): PodsDummy_image_picker_ios

### Community 47 - "Community 47"
Cohesion: 1.0
Nodes (1): MainActivity

### Community 48 - "Community 48"
Cohesion: 1.0
Nodes (1): SupabaseConfig

### Community 49 - "Community 49"
Cohesion: 1.0
Nodes (1): SyncWriteResult

### Community 50 - "Community 50"
Cohesion: 1.0
Nodes (1): AppProfile

### Community 51 - "Community 51"
Cohesion: 1.0
Nodes (1): OfflineSyncAction

### Community 52 - "Community 52"
Cohesion: 1.0
Nodes (1): CustomerModel

### Community 53 - "Community 53"
Cohesion: 1.0
Nodes (1): DashboardBundle

### Community 54 - "Community 54"
Cohesion: 1.0
Nodes (1): ProductionEntryModel

### Community 55 - "Community 55"
Cohesion: 1.0
Nodes (1): ExpenseEntry

### Community 56 - "Community 56"
Cohesion: 1.0
Nodes (1): FinanceSummary

### Community 57 - "Community 57"
Cohesion: 1.0
Nodes (1): FinanceRecord

### Community 58 - "Community 58"
Cohesion: 1.0
Nodes (0): 

### Community 59 - "Community 59"
Cohesion: 1.0
Nodes (0): 

### Community 60 - "Community 60"
Cohesion: 1.0
Nodes (0): 

### Community 61 - "Community 61"
Cohesion: 1.0
Nodes (0): 

### Community 62 - "Community 62"
Cohesion: 1.0
Nodes (0): 

### Community 63 - "Community 63"
Cohesion: 1.0
Nodes (0): 

### Community 64 - "Community 64"
Cohesion: 1.0
Nodes (0): 

### Community 65 - "Community 65"
Cohesion: 1.0
Nodes (0): 

### Community 66 - "Community 66"
Cohesion: 1.0
Nodes (0): 

### Community 67 - "Community 67"
Cohesion: 1.0
Nodes (0): 

### Community 68 - "Community 68"
Cohesion: 1.0
Nodes (0): 

### Community 69 - "Community 69"
Cohesion: 1.0
Nodes (0): 

### Community 70 - "Community 70"
Cohesion: 1.0
Nodes (0): 

### Community 71 - "Community 71"
Cohesion: 1.0
Nodes (0): 

### Community 72 - "Community 72"
Cohesion: 1.0
Nodes (0): 

### Community 73 - "Community 73"
Cohesion: 1.0
Nodes (0): 

### Community 74 - "Community 74"
Cohesion: 1.0
Nodes (0): 

### Community 75 - "Community 75"
Cohesion: 1.0
Nodes (0): 

### Community 76 - "Community 76"
Cohesion: 1.0
Nodes (0): 

### Community 77 - "Community 77"
Cohesion: 1.0
Nodes (0): 

### Community 78 - "Community 78"
Cohesion: 1.0
Nodes (0): 

### Community 79 - "Community 79"
Cohesion: 1.0
Nodes (0): 

### Community 80 - "Community 80"
Cohesion: 1.0
Nodes (0): 

### Community 81 - "Community 81"
Cohesion: 1.0
Nodes (0): 

### Community 82 - "Community 82"
Cohesion: 1.0
Nodes (0): 

### Community 83 - "Community 83"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **754 isolated node(s):** `PodsDummy_url_launcher_macos`, `PodsDummy_flutter_secure_storage_macos`, `main`, `wrapApp`, `ProviderScope` (+749 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 41`** (2 nodes): `url_launcher_macos-dummy.m`, `PodsDummy_url_launcher_macos`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 42`** (2 nodes): `flutter_secure_storage_macos-dummy.m`, `PodsDummy_flutter_secure_storage_macos`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 43`** (2 nodes): `url_launcher_ios-dummy.m`, `PodsDummy_url_launcher_ios`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 44`** (2 nodes): `flutter_secure_storage-dummy.m`, `PodsDummy_flutter_secure_storage`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 45`** (2 nodes): `flutter_local_notifications-dummy.m`, `PodsDummy_flutter_local_notifications`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 46`** (2 nodes): `image_picker_ios-dummy.m`, `PodsDummy_image_picker_ios`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 47`** (2 nodes): `MainActivity.kt`, `MainActivity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 48`** (2 nodes): `supabase_config.dart`, `SupabaseConfig`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 49`** (2 nodes): `sync_write_result.dart`, `SyncWriteResult`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 50`** (2 nodes): `app_profile.dart`, `AppProfile`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 51`** (2 nodes): `offline_sync_action.dart`, `OfflineSyncAction`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 52`** (2 nodes): `customer_model.dart`, `CustomerModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 53`** (2 nodes): `dashboard_bundle.dart`, `DashboardBundle`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 54`** (2 nodes): `production_entry_model.dart`, `ProductionEntryModel`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 55`** (2 nodes): `expense_entry.dart`, `ExpenseEntry`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 56`** (2 nodes): `finance_summary.dart`, `FinanceSummary`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 57`** (2 nodes): `finance_record.dart`, `FinanceRecord`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 58`** (1 nodes): `url_launcher_macos-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 59`** (1 nodes): `flutter_secure_storage_macos-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 60`** (1 nodes): `app_links-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 61`** (1 nodes): `connectivity_plus-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 62`** (1 nodes): `Pods-Runner-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 63`** (1 nodes): `shared_preferences_foundation-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 64`** (1 nodes): `Pods-RunnerTests-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 65`** (1 nodes): `Runner-Bridging-Header.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 66`** (1 nodes): `GeneratedPluginRegistrant.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 67`** (1 nodes): `url_launcher_ios-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 68`** (1 nodes): `app_links-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 69`** (1 nodes): `flutter_secure_storage-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 70`** (1 nodes): `connectivity_plus-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 71`** (1 nodes): `flutter_local_notifications-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 72`** (1 nodes): `Pods-Runner-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 73`** (1 nodes): `shared_preferences_foundation-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 74`** (1 nodes): `Pods-RunnerTests-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 75`** (1 nodes): `my_application.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 76`** (1 nodes): `generated_plugin_registrant.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 77`** (1 nodes): `build.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 78`** (1 nodes): `settings.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 79`** (1 nodes): `build.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 80`** (1 nodes): `utils.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 81`** (1 nodes): `win32_window.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 82`** (1 nodes): `resource.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 83`** (1 nodes): `generated_plugin_registrant.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 0` to `Community 1`, `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 15`, `Community 16`, `Community 17`, `Community 19`, `Community 20`?**
  _High betweenness centrality (0.325) - this node is a cross-community bridge._
- **Why does `package:flutter_riverpod/flutter_riverpod.dart` connect `Community 1` to `Community 2`, `Community 4`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 11`, `Community 12`, `Community 15`, `Community 16`, `Community 19`?**
  _High betweenness centrality (0.066) - this node is a cross-community bridge._
- **Why does `package:liquid_soap_tracker/core/models/app_profile.dart` connect `Community 4` to `Community 1`, `Community 2`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 11`, `Community 12`, `Community 16`, `Community 19`?**
  _High betweenness centrality (0.047) - this node is a cross-community bridge._
- **What connects `PodsDummy_url_launcher_macos`, `PodsDummy_flutter_secure_storage_macos`, `main` to the rest of the system?**
  _754 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._