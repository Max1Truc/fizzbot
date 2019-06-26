#/usr/bin/env ruby

#
# Fizzbot Solver GUI based on 'fizz.rb'
# (https://noopschallenge.com/challenges/fizzbot)
#
# The answer is automatically generated from each question data.
# The user can modify the provided answer before submitting it.
#
# Dependencies : fxruby
# (To install it run `gem install fxruby` with an up-to-date ruby installation)
#

# API calls libs
require "net/http"
require "json"

# Gui lib
require 'fox16'
include Fox

class MyWindow < FXMainWindow

  def initialize(app)
    # Invoke base class initialize first
    super(app, "FizzBot", :width => 600, :height => 300)

    # First API queries
    start = get_json('/fizzbot')
    @next_question_path = start['nextQuestion']
    @last_question = get_json(@next_question_path)
    
    # Main frame
    mainframe = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN)
    
    # Question info text box
    @lastquestion = FXText.new(mainframe, nil, 0, TEXT_READONLY|TEXT_WORDWRAP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @lastquestion.setText("# Message :\n#{@last_question["message"]}")
    
    # Bottom frame
    bottomframe = FXHorizontalFrame.new(mainframe, LAYOUT_FILL_X)
    
    # Answer field
    @answerfield = FXTextField.new(bottomframe, 100, :opts => LAYOUT_FILL_X|TEXTFIELD_ENTER_ONLY|TEXTFIELD_NORMAL)
    @answerfield.setText("Ruby")

    # The button
    @submit = FXButton.new(bottomframe, "Submit")
    @submit.connect(SEL_COMMAND) {
      answer_result = send_answer(@next_question_path, @answerfield.text)
      infobox(answer_result["result"].capitalize, answer_result["message"])
      if answer_result['result'] == 'correct' 
        # get the next question
        @next_question_path = answer_result['nextQuestion']
        @last_question = get_json(@next_question_path)
        
        # Display question
        @lastquestion.setText(
          "# Message :\n#{@last_question["message"]}\n\n" +
          "# Numbers : #{@last_question["numbers"].join(", ")}\n\n" +
          "# Rules :\n#{JSON.pretty_generate(@last_question["rules"])}"
        )
        
        # Preprocess answer
        @answerfield.setText(process @last_question)
      elsif answer_result['result'] == 'interview complete'
        infobox("Complete", "You completed the challenge, the app will now quit.")
        getApp().exit(0)
      end
    }
  end

  def create
    super
    show(PLACEMENT_SCREEN)
  end
end

def infobox(title, message)
  FXMessageBox.information(self, MBOX_OK, title, message)
end

def send_answer(path, answer)
  post_json(path, { :answer => answer })
end

# get data from the api and parse it into a ruby hash
def get_json(path)
  response = Net::HTTP.get_response(build_uri(path))
  return JSON.parse(response.body)
end

# post an answer to the noops api
def post_json(path, body)
  uri = build_uri(path)

  post_request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
  post_request.body = JSON.generate(body)

  response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) do |http|
    http.request(post_request)
  end

  return JSON.parse(response.body)
end

def build_uri(path)
  URI.parse("https://api.noopschallenge.com" + path)
end

def divisible?(a, b)
  (a % b).zero?
end

def process(question)
  answers = []
  question["numbers"].each do |number|
    result = ""
    question["rules"].each do |rule|
      if divisible? number, rule["number"]
        result << rule["response"]
      end
    end
    
    if result == ""
      answers << number
    else
      answers << result
    end
  end
  
  return answers.join(" ")
end

if __FILE__ == $0
  # Construct an application
  application = FXApp.new("Fizzbot GUI", "Noops Challenge")

  # Construct the main window
  MyWindow.new(application)

  # Create the application
  application.create

  # Run it
  application.run
end
