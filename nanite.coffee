class NaniteGame extends atom.Game
  constructor: ->
    super
    atom.input.bind atom.key.ENTER, 'hi'

  update: (dt) ->
    if atom.input.pressed 'hi'
      console.log "hi"

  draw: ->
    atom.context.fillStyle = 'black'
    atom.context.fillRect 0, 0, atom.width, atom.height

game = new NaniteGame

window.onblur = -> game.stop()
window.onfocus = -> game.run()

game.run()
