# encoding: utf-8
module DoubleEntry
  class DoubleEntryError < RuntimeError; end
  class UnknownAccount < DoubleEntryError; end
  class AccountIdentifierTooLongError < DoubleEntryError; end
  class ScopeIdentifierTooLongError < DoubleEntryError; end
  class TransferNotAllowed < DoubleEntryError; end
  class TransferIsNegative < DoubleEntryError; end
  class TransferCodeTooLongError < DoubleEntryError; end
  class DuplicateAccount < DoubleEntryError; end
  class DuplicateTransfer < DoubleEntryError; end
  class AccountWouldBeSentNegative < DoubleEntryError; end
  class AccountWouldBeSentPositiveError < DoubleEntryError; end
  class MismatchedCurrencies < DoubleEntryError; end
  class MissingAccountError < DoubleEntryError; end
end
