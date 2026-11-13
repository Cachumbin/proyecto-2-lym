object Animal
object Dog extends Animal
object Caja[T](val contenido: T)

method main {
  val entero: Int = 1 + 2 * 3
  val verdad: Boolean = entero > 2 and true
  val letra: Char = 'a'
  val texto: String = "hola ${entero} $letra"
  val decimal: Decimal = 1.5 + entero
  var contador: Int = 0
  contador = contador + 1
  val caja: Caja[Int] = new Caja[Int](entero)
  val inferida = new Caja("x")
  val dentro: String = inferida.contenido
  val perro: Animal = new Dog
  val maximo = if entero > 2 then entero else 0
  print("listo")
}
