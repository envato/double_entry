# encoding: utf-8
module DoubleEntry

  class UnknownAccount < RuntimeError; end
  class AccountIdentifierTooLongError < RuntimeError; end
  class TransferNotAllowed < RuntimeError; end
  class TransferIsNegative < RuntimeError; end
  class TransferCodeTooLongError < RuntimeError; end
  class DuplicateAccount < RuntimeError; end
  class DuplicateTransfer < RuntimeError; end
  class AccountWouldBeSentNegative < RuntimeError; end

end
