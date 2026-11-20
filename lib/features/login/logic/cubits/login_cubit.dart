import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:odoo_mobile_app/core/repository/odoo_repository.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final OdooRepository repository;

  LoginCubit(this.repository) : super(LoginInitial());

  Future<void> authenticateUser(String email, String password, {String? db}) async {
    emit(LoginLoading());
    try {
      await repository.login(email, password, db: db);
      emit(LoginSuccess());
    } catch (e) {
      emit(LoginError(e.toString().replaceAll("Exception: ", "")));
    }
  }
}
