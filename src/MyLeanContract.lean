import Examples.Hello
import LeanCairo.Core.Spec.ContractSpec

open LeanCairo.Core.Spec

namespace MyLeanContract

def contract : ContractSpec :=
  Examples.Hello.contract

end MyLeanContract
