class Game
  constructor: ->
    @fps = 30
    input.bind input.key.ENTER, 'hi'
  update: (dt) ->
    if input.pressed 'hi'
      console.log "hi"
  draw: ->
  run: ->
    @last_step = Date.now()
    @loop_interval = setInterval =>
      @step()
    , 1000/@fps
  stop: ->
    clearInterval @loop_interval if @loop_interval?
    @loop_interval = null
  step: ->
    now = Date.now()
    dt = now - @last_step
    @last_step = now
    @update(dt)
    @draw()
    input.clearPressed()

game = new Game

canvas = document.getElementById('nanite')
window.onresize = (e) ->
  canvas.width = window.innerWidth
  canvas.height = window.innerHeight
  game.draw()
window.onresize()
window.onblur = -> game.stop()
window.onfocus = -> game.run()

game.run()
