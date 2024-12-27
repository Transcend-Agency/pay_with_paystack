enum TransactionErrorType {
  noInternetConnection('Network unavailable. Please try again later.'),
  paymentCancelled('The payment was cancelled by the user.'),
  unexpectedError('An unknown error occurred. Please try again later.'),
  transactionFailed(
      'The transaction failed. Please contact support or try again.');

  const TransactionErrorType(this.message);

  final String message;
}
