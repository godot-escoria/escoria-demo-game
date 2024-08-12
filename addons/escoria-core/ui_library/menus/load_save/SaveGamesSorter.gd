class_name SaveGamesSorter

static func sort_by_date_descending(a, b):
	if Time.get_unix_time_from_datetime_dict(a.date) > Time.get_unix_time_from_datetime_dict(b.date):
		return true
	return false
	
static func sort_by_date_ascending(a, b):
	if Time.get_unix_time_from_datetime_dict(a.date) < Time.get_unix_time_from_datetime_dict(b.date):
		return true
	return false
