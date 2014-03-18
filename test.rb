allows = []
File.foreach("config/checklist.csv") do |csv_line|
    r = /"([\w]*)";"([\w]*)";"([a-zA-Z-]*)";"([\w\.-]*)";"([\w\.-]*)"/
    csv_row = r.match csv_line
    # puts "csv_row = #{csv_row}"
    allows.push csv_row[1]
    allows.push [ csv_row[2],csv_row[3],csv_row[4],csv_row[5] ].join(' ')
end
# puts allows
allows = allows.uniq.map { | name | name.strip }