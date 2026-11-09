# Evals for the support bot in lib/support.dart. The worker builds it once and answers every test case.
worker dart run bin/evalworker.dart

test_case "refund after the window" "Can I still return my shoes? They arrived 40 days ago."
  target lib/support.dart#answer
  matches "30[- ]day"   # "30 days" and "30-day window" are both right
  judge "Says a refund isn't possible anymore, politely"

test_case "missing package" "My package never showed up and I'm getting really annoyed."
  target lib/support.dart#answer
  matches "order (number|id|#)"
  judge "Asks for the order number before promising a refund or resend"

test_case "refund inside the window" "My shoes arrived last week and they don't fit. Can I send them back?"
  target lib/support.dart#answer
  judge "Says they can return them for a refund"
