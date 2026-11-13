object Caja[T](val contenido: T)
object Par[A, B](val primero: A, val segundo: B)

method main {
  val entero: Int = 42
  val verdad: Boolean = true
  val letra: Char = 'a'
  val texto: String = "hola"
  var contador: Int = 0

  val cajaEntero: Caja[Int] = new Caja[Int](entero)
  val cajaTexto: Caja[String] = new Caja[String](texto)
  val par: Par[Char, Boolean] = new Par[Char, Boolean](letra, verdad)
  val cajaDeCajas: Caja[Caja[Int]] = new Caja[Caja[Int]](cajaEntero)
}
