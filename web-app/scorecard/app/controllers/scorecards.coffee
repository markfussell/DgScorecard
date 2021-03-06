Spine = require('spine')
Scorecard = require('models/scorecard')
Player = require('models/player')

class Scorecards extends Spine.Controller
  events:
    'click .holeScore': 'enterHoleScore'
    'click button': 'submitScore'
    'click #addPlayer': 'addPlayer'
    'click .editPlayer': 'editPlayer'
    'click .removePlayer': 'removePlayer'

constructor: ->
  super
  @currentCourse
  Player.fetch()
  Spine.bind 'changeCourse', (courseObj) =>
    @resetCourse(courseObj)

render: ->
  #@html require('views/card/card')(@course)
  @log

  # detrmine nines (as in how many 9's, since most courses will be played in holes by a factor of nine)
  #always render the first nine
  @renderNine(1)
  #second 9 is a maybe
  if @currentCourse.holes > 9
    @renderNine(2)
  if @currentCourse.holes > 18
    @renderNine(3)
  @renderTally()

renderNine: (n)->
  switch n
    when 1
      startHole = 1
      endHole = 9
    when 2
      startHole = 10
      endHole = 18
    when 3
      startHole = 19
      endHole = 27
    else
      startHole = 1
      endHole = 9
  @el.append require('views/card/card')({nine: n, startHole: startHole, endHole: endHole})
  @renderRow(n, startHole, endHole)

renderRow: (nine, startHole, endHole)->
  for player in Player.all()
    player.startHole = startHole
    player.endHole = endHole
    $('tbody[data-nine="' + nine + '"]').append require('views/card/playerRow')(player)

renderTally: ->
  @el.append require('views/card/tally')
  for player in Player.all()
    $('#tallies tbody').append require('views/card/tallyRow')(player)
    @calcScoreTally(player)

enterHoleScore: (e)->
  cell = $(e.target)
  holeNum = cell.data('hole')
  #find the player this row belongs to
  playerId = cell.parent().data('player')
  player = Player.find(playerId)
  #@log("enter a score for hole number:" + cell.data('holenum'))
  holeScore = prompt("score ('bird' = -1, 'bog'=1)", '0')
  if isNaN(holeScore)
    if holeScore is 'bird'
      holeScore = -1
    else if holeScore is 'bog'
      holeScore = 1
    else
      alert "non-number entered, setting to 0 (par)"
      holeScore = 0
  cell.html holeScore
  player.scores[holeNum] = parseInt(holeScore, 10)
  player.save()
  @calcScoreTally(player)

calcScoreTally: (player)->
  tally = 0
  for holeScore in player.scores
    tally += holeScore
  #use jquery to select tally row, find the score input, and inject tally as value
  @$("tr[data-player='#{player.id}'] input[name='score']").val(tally)
  return tally

submitScore: (e)->
  e.preventDefault()
  button = $(e.target)
  row = button.parent().parent()
  # <tr><td><button></button></td></tr>
  playerId = row.data('player')
  player = Player.find(playerId)
  inputScore = row.find("input[name='score']")
  scoreVal = inputScore.val()
  inputNotes = row.find("input[name='notes']")
  notesVal = inputNotes.val()
  if confirm ("#{player.name} \n score: #{scoreVal} \n notes: #{notesVal}")
    scorecard = new Scorecard(playerEmail: player.name, score: scoreVal, 'course.id': @currentCourse.id, notes: notesVal, inProgress: false)
    scorecard.save()
    #@log scorecard
    scorecard.bind "update", ->
      #console.log 'update triggered'
      button.attr('disabled', 'disabled').text('done')
      inputScore.attr('disabled', 'disabled')
      inputNotes.attr('disabled', 'disabled')
      @unbind "update"

resetCourse: (courseObj)->
  change = true
  if @currentCourse
    change = confirm('are you sure you want to abandon current course?')
    if confirm 'would you like to reset everyones scores?'
      @resetPlayerScores()
  if change
    @currentCourse = courseObj
    @html ''
    @render()

resetPlayerScores: ->
  for player in Player.all()
    player.scores = {}
    player.save()

addPlayer: (e)->
  e.preventDefault()
  newPlayer = new Player(name: prompt('google id', '@gmail.com'), scores:
    {})
  newPlayer.save()
  #need to trigger a re-render w/out losing all scores... but they are saved for each player obj
  @html ''
  @render() # not most efficient approach...

editPlayer: (e)->
  e.preventDefault()
  #@log $(e.target).parent().parent()
  playerId = $(e.target).parent().parent().data('player')
  player = Player.find(playerId)
  player.name = prompt('google id', player.name)
  player.save()
  #@log player
  @html ''
  @render() # not most efficient approach...

removePlayer: (e)->
  e.preventDefault()
  @log 'remove time'
  if confirm 'ya sure?'
    playerId = $(e.target).parent().parent().data('player')
    player = Player.find(playerId)
    player.destroy()
  @html ''
  @render()
# not most efficient approach...

module.exports = Scorecards
