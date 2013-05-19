require 'JSON'

json = JSON.parse(IO.read("description.json"))

subjects = Array.new

json.each { |x|
  subject = subjects.assoc(x['subject'])

  if (subject == nil)
    subjects.push [x['subject'], 1, 0]
  else
    subject[1] += 1
  end

  if (x['description'] == "Contact the department for further information")
    subject = subjects.assoc(x['subject'])
    subject[2] += 1
  end
}

empty_subjects = Array.new

subjects.each { |subject|
  #print "#{subject[0]} #{subject[1]} #{subject[2]}"
  #print (subject[1] == subject[2]) ? " - All Empty\n" : "\n"
  empty_subjects.push subject if (subject[1] == subject[2])
}

empty_subjects.each { |empty_subject| puts empty_subject[0] }