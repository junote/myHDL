package myworkshop

import spinal.core._
import spinal.lib._
import spinal.lib.bus.amba4.axilite._

case class MyAxi4Lite() extends Component {
  val io = new Bundle {
    val aLiteCtrl = slave(AxiLite4(32, 32))
    val en = out Bool () setAsReg () init (False)
    val plus = out Bool () setAsReg () init (False)
    val cnt = in UInt (64 bits)
  }
  noIoPrefix()
  AxiLite4SpecRenamer(io.aLiteCtrl)
  val _ = new Area {
    io.plus.clear()
    val busCtrl = new AxiLite4SlaveFactory(io.aLiteCtrl)
    busCtrl.readAndWrite(
      io.en,
      address = 0,
      bitOffset = 0,
      documentation = "en:enable"
    )
    busCtrl.readAndWrite(
      io.plus,
      address = 4,
      bitOffset = 4,
      documentation = "pwm driver"
    )
    busCtrl.readMultiWord(
      io.cnt,
      address = 8,
      documentation = "read cnt value"
    )
    busCtrl.printDataModel()
  }.setName("")
}

case class MyAxi4Lite2() extends Component {
  val io = new Bundle {
    val aLiteCtrl = slave(AxiLite4(32, 32))
    val en = out Bool () setAsReg () init (False)
    val plus = out Bool () setAsReg () init (False)
    val cnt = in UInt (64 bits)
    val ioin0 = in Bool ()
    val ioin1 = in Bool ()
    val out0 = out Bool () setAsReg () init (False)
    val out1 = out Bool () setAsReg () init (False)
    val out2 = out Bool () setAsReg () init (False)
  }
  noIoPrefix()
  AxiLite4SpecRenamer(io.aLiteCtrl)
  val _ = new Area {
    val busCtrl = new AxiLite4SlaveFactory(io.aLiteCtrl)
    busCtrl.createReadAndWrite(UInt(32 bits), 0, 0) init (U"h87654321")
    busCtrl.createReadOnly(UInt(32 bits), 4, 0) init (U"h12345678")
    busCtrl.createReadOnly(UInt(32 bits), 8, 0) init (U(0x2332))
    busCtrl.read(io.ioin1, 12, 1)
    busCtrl.write(io.out0, 12, 2)
    busCtrl.drive(io.out1,12,3)
    busCtrl.driveAndRead(io.out2,12,4)


  }.setName("")
}

object MyAxi4LiteVerilog {
  def main(args: Array[String]) {
    // SpinalConfig(targetDirectory = "rtl").generateVerilog(new MyAxi4Lite)
    SpinalConfig(targetDirectory = "rtl").generateVerilog(new MyAxi4Lite2)
  }
}

/*
object MyAxiLiteSimApp extends App{
    import spinal.core.sim._
    import spinal.lib.bus.amba4.axilite.sim._

    SimConfig.withWave.compile(MyAxi4Lite()).doSim{dut=>
        val aliteDrv = AxiLite4Driver(dut.io.aLiteCtrl,dut.clockDomain)
        dut.io.cnt #= BigInt("f000f000f000",16)
        dut.clockDomain.forkStimulus(period=10)
        aliteDrv.reset()
        dut.clockDomain.waitSampling()
        aliteDrv.write(0,1)
        aliteDrv.read(0)
        aliteDrv.write(4,0x10)
        aliteDrv.read(8)
        aliteDrv.read(0xc)
        dut.clockDomain.waitSampling(count=10)
    }
}
 */
