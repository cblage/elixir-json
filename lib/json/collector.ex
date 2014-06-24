defrecord JSON.Collector,
  array: JSON.Collector.Array.SortedList,
  object: JSON.Collector.Object.Map
do
  record_type \
    array: JSON.Collector.Array.t,
    object: JSON.Collector.Object.t
end
