 for x = 1 : 70
dA = branchA.nodePropagation();
branchA.stress = branchA.stress + dA(1);
branchA.unhappiness = branchA.unhappiness + dA(2);
branchA.timeStep(1000);
dB = branchB.nodePropagation();
branchB.stress = branchB.stress + dB(1);
branchB.unhappiness = branchB.unhappiness + dB(2);
branchB.timeStep(1000);
d1 = director1.nodePropagation();
director1.stress = director1.stress + d1(1);
director1.unhappiness = director1.unhappiness + d1(2);
director1.timeStep(1000);

dE = branchE.nodePropagation();
branchE.stress = branchE.stress + dE(1);
branchE.unhappiness = branchE.unhappiness + dE(2);
branchE.timeStep(1000);
dF = branchF.nodePropagation();
branchF.stress = branchF.stress + dF(1);
branchF.unhappiness = branchF.unhappiness + dF(2);
branchF.timeStep(1000);
dG = branchG.nodePropagation();
branchG.stress = branchG.stress + dG(1);
branchG.unhappiness = branchG.unhappiness + dG(2);
branchG.timeStep(1000);
dH = branchH.nodePropagation();
branchH.stress = branchF.stress + dH(1);
branchH.unhappiness = branchH.unhappiness + dH(2);
branchH.timeStep(1000);
d3 = director3.nodePropagation();
director3.stress = director3.stress + d3(1);
director3.unhappiness = director3.unhappiness + d3(2);
director3.timeStep(1000);
d4 = director4.nodePropagation();
director4.stress = director4.stress + d4(1);
director4.unhappiness = director4.unhappiness + d4(2);
director4.timeStep(1000);
 end

 branchA.plotHistory();
 branchB.plotHistory();
 director1.plotHistory();
 
 branchE.plotHistory();
 branchF.plotHistory();
 branchG.plotHistory();
 director3.plotHistory();
 
 branchH.plotHistory();
 director4.plotHistory();