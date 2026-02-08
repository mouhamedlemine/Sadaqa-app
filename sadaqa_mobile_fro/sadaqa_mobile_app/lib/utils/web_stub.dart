typedef FbSuccess = void Function(String token);
typedef FbFailure = void Function();

void addFacebookSuccessListener(FbSuccess cb) {}
void addFacebookFailureListener(FbFailure cb) {}
void callFacebookLoginJS() {}
