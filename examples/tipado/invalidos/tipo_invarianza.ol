object Animal
object Dog extends Animal
object Caja[T](val contenido: T)

method main {
  val c: Caja[Animal] = new Caja[Dog](new Dog)
}
