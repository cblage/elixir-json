defrecord JSON.Collector,
  array: JSON.Collector.Array.List,
  object: JSON.Collector.Object.HashDict
do
  record_type \
    array: JSON.Collector.Array.t,
    object: JSON.Collector.Object.t
end
