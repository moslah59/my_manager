class AuthService {
  bool login(String email, String password) {
    const correctEmail = 'admin@gmail.com';
    const correctPassword = '123456';

    if (email == correctEmail && password == correctPassword) {
      return true;
    }

    return false;
  }
}