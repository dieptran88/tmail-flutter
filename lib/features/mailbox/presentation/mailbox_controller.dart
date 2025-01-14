import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:core/presentation/utils/responsive_utils.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:model/mailbox/select_mode.dart';
import 'package:tmail_ui_user/features/base/base_controller.dart';
import 'package:tmail_ui_user/features/mailbox/domain/constants/mailbox_constants.dart';
import 'package:tmail_ui_user/features/login/domain/usecases/delete_credential_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/get_all_mailboxes_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/get_all_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_node.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree_builder.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/mailbox_dashboard_controller.dart';
import 'package:tmail_ui_user/main/routes/app_routes.dart';

class MailboxController extends BaseController {

  final GetAllMailboxInteractor _getAllMailboxInteractor;
  final DeleteCredentialInteractor _deleteCredentialInteractor;
  final TreeBuilder _treeBuilder;
  final ResponsiveUtils responsiveUtils;

  final mailboxDashBoardController = Get.find<MailboxDashBoardController>();

  MailboxController(this._getAllMailboxInteractor, this._deleteCredentialInteractor, this._treeBuilder, this.responsiveUtils);

  final folderMailboxTree = MailboxTree(MailboxNode.root()).obs;
  final selectedMailbox = PresentationMailbox.createMailboxEmpty().obs;

  @override
  void onReady() {
    super.onReady();
    if (mailboxDashBoardController.sessionCurrent != null) {
      getAllMailboxAction(
          mailboxDashBoardController.sessionCurrent!.accounts.keys.first);
    }
  }

  void getAllMailboxAction(AccountId accountId) async {
    consumeState(_getAllMailboxInteractor.execute(accountId));
  }

  @override
  void onData(Either<Failure, Success> newState) {
    super.onData(newState);
    newState.map((success) {
      if (success is GetAllMailboxSuccess) {
        _buildTree(success.folderMailboxList);
        _setDefaultSelected(success.defaultMailboxList);
      }
    });
  }

  @override
  void onDone() {
  }

  @override
  void onError(error) {
  }

  void _buildTree(List<PresentationMailbox> folderMailboxList) async {
    folderMailboxTree.value = await _treeBuilder.generateMailboxTree(folderMailboxList);
  }

  void _setDefaultSelected(List<PresentationMailbox> defaultMailboxList) {
    try {
      final mailboxDefault = defaultMailboxList
          .firstWhere((presentationMailbox) => presentationMailbox.role == Role(MailboxConstants.ROLE_DEFAULT));
      selectedMailbox.value = mailboxDefault;
      mailboxDashBoardController.mailboxCurrent.value = mailboxDefault;
    } catch (e) {}
  }

  SelectMode getSelectMode(PresentationMailbox presentationMailbox) {
    return presentationMailbox.id == selectedMailbox.value.id
      ? SelectMode.ACTIVE
      : SelectMode.INACTIVE;
  }

  void selectMailbox(
      BuildContext context,
      PresentationMailbox presentationMailboxSelected,
      {
        required GlobalKey<ScaffoldState> keyWidgetMailboxDashBoard
      }
  ) {
    selectedMailbox.value = presentationMailboxSelected;
    mailboxDashBoardController.mailboxCurrent.value = presentationMailboxSelected;

    if (responsiveUtils.isMobile(context)) {
      goToThread(keyWidgetMailboxDashBoard: keyWidgetMailboxDashBoard);
    }
  }

  void goToThread({required GlobalKey<ScaffoldState> keyWidgetMailboxDashBoard}) {
    keyWidgetMailboxDashBoard.currentState?.openEndDrawer();
  }

  void _deleteCredential() async {
    await _deleteCredentialInteractor.execute();
  }

  void closeMailboxScreen() {
    _deleteCredential();
    Get.offAllNamed(AppRoutes.LOGIN);
  }
}