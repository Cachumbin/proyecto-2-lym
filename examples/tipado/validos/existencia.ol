object Perro extends Animal
object Animal
object Caja[T](val contenido: T) extends Base[T]
object Base[A]
object Par[K, V](val clave: K, val valor: V)

Perro.ladrar = method(veces: Int): String {
  "guau"
}

method main {
  val perro: Animal = new Perro
  val caja: Caja[Perro] = new Caja[Perro](new Perro)
  val par: Par[String, Int] = new Par("a", 1)
  val luna = new Perro
  val mensaje: String = luna.ladrar(2)
  val ladrador = new Perro {
    override ladrar(veces: Int): String = {
      "grr"
    }
  }
}
