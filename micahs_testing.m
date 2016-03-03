clear

p1 = person(0.28,0.20,0.45,3.1,2.2);
p2 = person(0.20,0.18,0.40,2.1,2);
p3 = person(0.30,0.95,0.55,2.5,1.8);
p4 = person(0.20,0.15,0.60,0.5,2);

pDummy = person(0.28,0.20,0.45,3.1,2.2);
NDummy = node('Dummy',4,[],[],0.1,0.3,1,0.15,0.5,0.5,2);
NDummy.startRelation();

N = node('Test',4,[],[],0.1,0.3,1,0.15,0.5,0.5,2);
N.addPerson(p1);
%N.addPerson(p2);
%N.addPerson(p3);
%N.addPerson(p4);

T = 1400;

p1U = [1:T];
p1S = [1:T];
p1E = [1:T];

p2U = [1:T];
p2S = [1:T];
p2E = [1:T];

p3U = [1:T];
p3S = [1:T];
p3E = [1:T];

p4U = [1:T];
p4S = [1:T];
p4E = [1:T];

NU = [1:T];
NS = [1:T];

for x = 1 : T
    
    NDummy.timeStep(1000);
    
    % Simulated churn
    %if x == 400
    %    p4.unhappiness = 0.18;
    %    p4.stress = 0.14;
    %    p4.experience = 1.1;
    %end
    
    % Something weird happened at a neighbor node
    %if x >= 800 && x <= 830
    %    N.unhappiness = N.unhappiness + 0.002;
    %    N.stress = N.stress + 0.002;
    %end
    
    % p4 (the new one) made a friend
    %if x >= 420
    %    d34 = p3.interactWith(p4, 2);
    %    d43 = p4.interactWith(p3, 1);
    %else
        d34 = [0,0,0];
        d43 = [0,0,0];
    %end
    
    % dnn = [U S E]
    d12 = p1.interactWith(p2, 2);
    d13 = p1.interactWith(p3, 2);
    d21 = p2.interactWith(p1, 1);
    d31 = p3.interactWith(p1, 1);
    
    % dnE = [U S E W]
    totalExp = 100 * (p1.experience + p2.experience + p3.experience + p4.experience);
    d1E = N.getWorkerDeltaFromEnvironment(p1,totalExp);
    d2E = N.getWorkerDeltaFromEnvironment(p2,totalExp);
    d3E = N.getWorkerDeltaFromEnvironment(p3,totalExp);
    d4E = N.getWorkerDeltaFromEnvironment(p4,totalExp);
    
    % dEn = [U S E W]
    dE1 = N.getEnvironmentDeltaFromWorker(p1);
    dE2 = N.getEnvironmentDeltaFromWorker(p2);
    dE3 = N.getEnvironmentDeltaFromWorker(p3);
    dE4 = N.getEnvironmentDeltaFromWorker(p4);
    
    p1.unhappiness = p1.unhappiness + d12(1) + d13(1) + d1E(1);
    p1.stress = p1.stress + d12(2) + d13(2) + d1E(2);
    p1.experience = p1.experience + d12(3) + d13(3) + d1E(3);
    
    p2.unhappiness = p2.unhappiness + d21(1) + d2E(1);
    p2.stress = p2.stress + d21(2) + d2E(2);
    p2.experience = p2.experience + d21(3) + d2E(3);
    
    p3.unhappiness = p3.unhappiness + d31(1) + d34(1) + d3E(1);
    p3.stress = p3.stress + d31(2) + d34(2) + d3E(2);
    p3.experience = p3.experience + d31(3) + d34(3) + d3E(3);
    
    p4.unhappiness = p4.unhappiness + d43(1) + d4E(1);
    p4.stress = p4.stress + d43(2) + d4E(2);
    p4.experience = p4.experience + d43(3) + d4E(3);
    
    N.unhappiness = N.unhappiness + dE1(1) + dE2(1) + dE3(1) + dE4(1);
    N.stress = N.stress + dE1(2) + dE2(2) + dE3(2) + dE4(2);
    
    
    
    p1.meditate(2);
    p2.meditate(1);
    %if x >= 420
    %    p3.meditate(2);
    %    p4.meditate(1);
    %else
        p3.meditate(1);
        p4.meditate(0);
    %end
    
    
    
    p1U(x) = p1.unhappiness;
    p1S(x) = p1.stress;
    p1E(x) = p1.experience;
    
    p2U(x) = p2.unhappiness;
    p2S(x) = p2.stress;
    p2E(x) = p2.experience;
    
    p3U(x) = p3.unhappiness;
    p3S(x) = p3.stress;
    p3E(x) = p3.experience;
    
    p4U(x) = p4.unhappiness;
    p4S(x) = p4.stress;
    p4E(x) = p4.experience;
    
    NU(x) = N.unhappiness;
    NS(x) = N.stress;
end

maxE1 = max(p1E);
maxE2 = max(p2E);
maxE3 = max(p3E);
maxE4 = max(p4E);
maxE = max([maxE1,maxE2,maxE3,maxE4]); % max efficiency

xs = 1 : T;



% Aggregate
figure('Name', 'Four-Person Test 1')
subplot(2,4,1)
plot(xs,p1U,'g',xs,p1S,'r')
axis([1,T,0,1])
title('Person 1')
subplot(2,4,2)
plot(xs,p2U,'g',xs,p2S,'r')
axis([1,T,0,1])
title('Person 2')
subplot(2,4,5)
plot(xs,p3U,'g',xs,p3S,'r')
axis([1,T,0,1])
title('Person 3')
subplot(2,4,6)
plot(xs,p4U,'g',xs,p4S,'r')
axis([1,T,0,1])
title('Person 4')

subplot(2,4,3)
plot(p1E,'Color','blue')
axis([1,T,0,maxE])
title('Person 1 Experience')
subplot(2,4,4)
plot(p2E,'Color','blue')
axis([1,T,0,maxE])
title('Person 2 Experience')
subplot(2,4,7)
plot(p3E,'Color','blue')
axis([1,T,0,maxE])
title('Person 3 Experience')
subplot(2,4,8)
plot(p4E,'Color','blue')
axis([1,T,0,maxE])
title('Person 4 Experience')

% Environment
figure('Name', 'Environment')
subplot(2,1,1)
plot(NU,'Color','green')
axis([1,T,0,1])
title('Environment Unhappiness')
subplot(2,1,2)
plot(NS,'Color','red')
axis([1,T,0,1])
title('Environment Stress')