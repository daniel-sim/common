Analytics = Segment::Analytics.new(
  write_key: ENV.fetch("segment_write_key", ""),
  on_error: proc { |status, msg| print msg }
)
