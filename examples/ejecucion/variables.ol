method main {
  var contador: Int = 0
  contador = contador + 1
  contador = contador * 10
  val letra: Char = 'z'
  val texto: String = "contador=$contador letra=$letra"
  println(texto)
  val maximo = if contador > 5 then contador else 5
  println("maximo $maximo")
}
