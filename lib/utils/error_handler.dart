String? handleErrorResponse(dynamic response) {
  String? errorMessage;
  switch (response.statusCode) {
    case 200:
      if (response.data["needsEmailVerification"] == true) {
        errorMessage =
            "Email not verified. Please check your email for verification.";
      } else {
        errorMessage = "Login successful.";
      }
      break;
    case 409:
      errorMessage =
          "Email already in use. Please use a different email or try logging in.";
      break;
    case 400:
      errorMessage = "Invalid request. Please check your input.";
      break;
    case 401:
      errorMessage = "Server error. Please try again later.";
      break;
    case 403:
      errorMessage = "Account access denied. Please contact support.";
      break;
    case 404:
      errorMessage = "Service not found. Please try again later.";
      break;
    case 422:
      errorMessage = "Validation error occurred.";
      break;
    case 429:
      errorMessage = "Too many login attempts. Please try again later.";
      break;
    case 500:
      errorMessage = "Invalid email or password.";
      break;
    case 502:
    case 503:
    case 504:
      errorMessage = "Service temporarily unavailable. Please try again later.";
      break;
    default:
      errorMessage = "Something went wrong. Please try again later.";
      break;
  }
  return errorMessage;
}
