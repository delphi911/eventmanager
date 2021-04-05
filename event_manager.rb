require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'


def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5,'0')[0..4]
end

def phonestatus(phone)
    status = "bad number" if phone.length < 10
    status = "good number" if phone.length == 10
    status = "bad number" if phone.length > 10
    status
end

def clean_phone_numbers(phone)
    phone = phone.scan(/\d+/).join("")
    if phone.length == 11 && phone[0]=="1"
        phone[0]= ""
    end
    phone
end

def legislators_by_zipcode(zipcode)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
    begin
        civic_info.representative_info_by_address(
            address: zipcode,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
    rescue
        'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end

def readtemplate
    template_letter = File.read('form_letter.erb')
end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exists?('output')

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter 
    end
end

def adv(regtime)
  zaman = DateTime.strptime(regtime, "%m/%d/%Y %k:%M")
  zaman.hour
end

def findDays(regdate)
  zaman = DateTime.strptime(regdate, "%m/%d/%Y %k:%M")
  zaman.wday
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true, 
  header_converters: :symbol
)

erb_template = ERB.new readtemplate
regdates = []
regdays = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode=clean_zipcode(row[:zipcode])
  phone = clean_phone_numbers(row[:homephone])
  status = phonestatus(phone.to_s)
  regDate = row[:regdate]
  regdays << findDays(regDate)
  puts "Processing #{id}: #{name} 's phone is #{phone} and this number is a #{status}"
  regdates << adv(regDate)

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  #save_thank_you_letter(id, form_letter)
  end # do

print "Most registered hour(s) : "
reghours = regdates.inject(Hash.new 0) { |h,d| h[d] += 1; h }
reghours.each { |k, v| print "#{k}, " if v == reghours.values.max }
puts ""
print "Most registered week day(s) :"
regweekdays = regdays.inject(Hash.new 0) { |h,d| h[d] += 1; h }
regweekdays.each { |k, v| print "#{k}, " if v == regweekdays.values.max }
