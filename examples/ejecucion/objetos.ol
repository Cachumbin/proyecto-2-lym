object Animal
object Dog extends Animal
object Caja[T](val contenido: T)
object Contador(var cuenta: Int)

Dog.ladrar = method(veces: Int): String {
  "guau x$veces"
}

method main {
  val c: Caja[Int] = new Caja[Int](41 + 1)
  println("caja ${c.contenido}")
  val perro = new Dog
  println(perro.ladrar(3))
  println(perro.getClass.getSimpleName)
  val n = new Contador(0)
  n.cuenta = n.cuenta + 5
  println("cuenta ${n.cuenta}")
}
