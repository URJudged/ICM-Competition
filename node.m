classdef node < handle
    %Node: 
    %   Detailed explanation goes here <-- Nope!
    
properties 
        name              % Name of the branch
        peopleL           % List of people in the node
        numPositions      % Number of possible people in the node (14 or 4)
        superior          % Pointer to the superior node
        underlings        % An array of pointers to underling nodes
        stress            % Between 0 and 1, varies with amount of work
        efficiency        % work done/total work
        work              % total work
        spread            % These two parameters define the parameters of the people added to this node
        prob              % See above
        unhappiness       % Between 0 and 1, varies with wage and interaction
        wages             % In terms of sigma, median per worker
        relationUp        % Relationship with superior, scales flow of stress and unhappiness
        relationDown      % Relationship with underlings, scales flow of stress and unhappiness
        graph             % A graph where the vertices are people and the edges are abstract interactions
        level             % Specifies what level of the company the node is at
        hiringOdds        % The chance that a single open slot will be filled at the end of a month.
        churnOdds         % A multiplier for the chance that an individual will be churned from this office.
        numPeopleHist     % A vector tracking number of people / time, for plotting
        stressHist        % Tracks stress / time, for plotting
        efficiencyHist    % Tracks efficiency / time, for plotting
        unhappinessHist   % Tracks unhappiness / time, for plotting
        wagesHist         % Tracks wages / time, for plotting
    end
    
    methods
        function obj = node(name,numPositions,superior...
                ,underlings,stress,efficiency,work,unhappiness...
                ,relationUp,relationDown,level)
            obj.name = name;
            obj.numPositions = numPositions;
            obj.superior = superior;
            obj.underlings = underlings;
            obj.stress = stress;
            obj.efficiency = efficiency;
            obj.work = work;
            obj.unhappiness = unhappiness;
            obj.wages = 0;
            obj.relationUp = relationUp;
            obj.relationDown = relationDown;
            obj.graph = zeros(numPositions,numPositions);
            obj.numPeopleHist = [obj.numPeople()];
            obj.stressHist = [obj.stress];
            obj.efficiencyHist = [obj.efficiency];
            obj.unhappinessHist = [obj.unhappiness];
            obj.wagesHist = [obj.wages];
            pd = makedist('Triangular');
            obj.level = level;
            obj.spread = 1;
            if level == 5
                obj.prob = 10;
                obj.hiringOdds = 1;
                obj.churnOdds = 0;
            elseif level == 4
                obj.prob = 8;
                obj.hiringOdds = 1/(7+1);
                obj.churnOdds = 5;
            elseif level == 3
                obj.prob = 4;
                obj.hiringOdds = 1/(6+1);
                obj.churnOdds = 10;
            elseif level == 2
                obj.prob = 2;
                obj.hiringOdds = 1/(4.5+1);
                obj.churnOdds = 10;
            else
                obj.prob = 0.8;
                obj.spread = 0.1;
                obj.hiringOdds = 1/(2+1);
                obj.churnOdds = 7;
            end
            
            % Start filling the node. The rest will be done outside
            pd1 = makedist('Triangular','a',0.1,'b',0.2,'c',0.3);
            pd2 = makedist('Triangular','a',0,'b',3,'c',10);
            if obj.numPositions == 4
                for i = 1:3
                    obj.addPerson(person(random(pd1,1,1)...
                        ,random(pd1,1,1),random(pd,1,1)...
                        ,random(pd2,1,1),random(makedist('Triangular','a',...
                        obj.prob-obj.spread,'b',obj.prob,'c',obj.prob+obj.spread),1,1)));
                end
            else
                for i = 1:10
                    obj.addPerson(person(random(pd1,1,1)...
                        ,random(pd1,1,1),random(pd,1,1)...
                        ,random(pd2,1,1),random(makedist('Triangular','a',...
                        obj.prob-obj.spread,'b',obj.prob,'c',obj.prob+obj.spread),1,1)));
                end
            end
        end
        
        function obj = timeStep(obj, totalExp)
            % Internally progresses the node by a single timestep.
            % Currently handles node updating of environment variables
            % based on neighboring nodes.
            
            %deltaVector = [obj.nodePropagation(),0,0];
            %deltaVector = deltaVector + addEnvironmentalDeltaFromWorker(totalExp);
            
            obj.nodePeopleInteractionsTimestep(totalExp);
            
            obj.numPeopleHist = [obj.numPeopleHist, obj.numPeople()];
            obj.stressHist = [obj.stressHist, obj.stress];
            obj.efficiencyHist = [obj.efficiencyHist, obj.efficiency];
            obj.unhappinessHist = [obj.unhappinessHist, obj.unhappiness];
            obj.wagesHist = [obj.wagesHist, obj.wages];
        end
        
        function deltaVector = nodePropagation(obj)
            % Calculates the amount of stress and unhappiness that
            % propagates from neighboring nodes to itself.
            % [deltaS, deltaU]
            underlingsArrayDimensions = size(obj.underlings);
            numUnderlings = underlingsArrayDimensions(2);
            sup = obj.superior;
            
            avgUnderlingUnhappiness = 0; % accumulator
            avgUnderlingStress = 0; % accumulator
            underlingInefficiency = 0; % accumulator
            
            if numUnderlings == 0
                avgUnderlingUnhappiness = obj.unhappiness; % so it doesn't change
                avgUnderlingStress = obj.stress; % so it doesn't change
            else
                for underling = 1:numUnderlings
                    avgUnderlingUnhappiness = avgUnderlingUnhappiness+...
                        obj.underlings(underling).unhappiness;
                    avgUnderlingStress = avgUnderlingStress+...
                        obj.underlings(underling).stress;
                    underlingInefficiency = underlingInefficiency+...
                        (1 - obj.underlings(underling).efficiency);
                end        

                avgUnderlingUnhappiness = avgUnderlingUnhappiness...
                    /(0.01+numUnderlings);
                avgUnderlingStress = avgUnderlingStress...
                    /(0.01+numUnderlings);
            end
            
            if isempty(sup)
                supUnhappiness = obj.unhappiness; % so it stays unchanged
                supStress = obj.stress; % so it stays unchanged
            else
                supUnhappiness = sup.unhappiness;
                supStress = sup.stress;
            end
            
            Kp = 0.005;   % promotion probability coefficient
            Tp = 0.40; % threshold promotion probability
            Ke = 0.005;   % efficiency coefficient
            Gamma = 0.001;
            
            if obj.level == 5
                Tp = 0;
            end
            
            deltaU = Kp * (obj.promotionProb()-Tp) * obj.unhappiness...
                * (1 - obj.unhappiness) + (1/15) * obj.unhappiness...
                * (1 - obj.unhappiness) * ((obj.relationUp...
                * (supUnhappiness-obj.unhappiness)) + (obj.relationDown...
                * (avgUnderlingUnhappiness-obj.unhappiness)));
            deltaS = Ke*(1 - obj.efficiency) * obj.stress * (1 - obj.stress)...
                + Gamma * underlingInefficiency * (1 - obj.stress)...
                + (1/15) * obj.stress * (1 - obj.stress) * (...
                obj.relationUp * (supStress-obj.stress) + obj.relationDown...
                * (avgUnderlingStress-obj.stress)); 
            deltaVector = [deltaS, deltaU];
            
            if isnan(deltaU)
                'Promotion Prob', obj.promotionProb()
                'Unhappiness', obj.unhappiness
                'Rel Up & Down', obj.relationUp, obj.relationDown
                'Avg Underling U', avgUnderlingUnhappiness
            end
        end
        
        function fig = plotHistory(obj)
            % NSEUW
            T = size(obj.numPeopleHist,2);
            fig = figure('Name', strcat('History of: ', obj.name));
            
            subplot(2,2,1)
            plot(obj.numPeopleHist)
            title('Number of People')
            axis([0,T,0,obj.numPositions])
            
            subplot(2,2,2)
            plot(1:T,obj.stressHist,'r',1:T,obj.unhappinessHist,'g')
            title('Stress and Unhappiness')
            axis([0,T,0,1])
            
            subplot(2,2,3)
            plot(obj.efficiencyHist)
            title('Efficiency')
            axis([0,T,0,1])
            
            subplot(2,2,4)
            plot(obj.wagesHist)
            title('Wages')
            axis([0,T,0,12]) % Even the CEO shouldn't exceed this value
        end
        
        function prob = promotionProb(obj)
            % Calculates probability of a promotion
            if isempty(obj.superior)
                prob = 0;
            else
                supNumPositions = obj.superior.numPositions;
                supNumPeople = obj.superior.numPeople;
                if supNumPositions <= supNumPeople
                    prob = 0;
                else
                    if obj.numPeople > 1
                        prob = ((supNumPositions - supNumPeople)...
                            / (0.01 + supNumPositions)) * (obj.numPeople...
                            / (0.01 + obj.numPositions)) * obj.efficiency;
                    else
                        prob = 0;
                    end
                end
            end
        end
    
        function obj = promote(obj)
            % Decides whether to promote someone, and changes
            %   the numPeople and unhappiness of both relevant
            %   nodes appropriately
            epsilon = 0.05; % related to amount of unhappiness the promotee
                            %   brings with them to their new position
            probThreshhold = obj.promotionProb();
            prob = rand;   % Uniformly dist. on (0, 1)
            
            if prob <= probThreshhold
                sup = obj.superior;
                promoted = obj.promoteWho();
                
                objOldNumPeople = obj.numPeople;
                supOldNumPeople = sup.numPeople;
                
                promoted.wage = random(sup.probLevel(),1,1);
                
                sup.addPerson(promoted);
                obj.removePerson(promoted);
                
                obj.unhappiness = (obj.unhappiness - epsilon)...
                    * objOldNumPeople / obj.numPeople;
                sup.unhappiness = (sup.unhappiness + epsilon)...
                    * supOldNumPeople / sup.numPeople;
            end
        end
        
        function obj = addPerson(obj, hire)
            % Adds a new person to the node
            obj.peopleL = [obj.peopleL, hire];
            wageL = [];
            for i = obj.peopleL
                wageL = i.wage;
            end
            obj.wages = median(wageL);
        end
        
        function nPeople = numPeople(obj)
            % Determines the number of people in the node
            nPeople = size(obj.peopleL,2);
        end
        
        function obj = removePerson(obj, worker)
            % Removes a person from the node, not the company
            workerIndex = find(obj.peopleL==worker);
            obj.peopleL = obj.peopleL(obj.peopleL ~= worker);
            obj.graph = obj.graph([1:workerIndex-1,workerIndex+1:end]...
                ,[1:workerIndex-1,workerIndex+1:end]);
            obj.graph = [obj.graph,zeros(size(obj.graph,1),1)];
            obj.graph = [obj.graph;zeros(1,size(obj.graph,2))];
            wageL = [];
            for i = obj.peopleL
                wageL = [wageL, i.wage];
            end
            obj.wages = median(wageL);
        end
        
        function promoted = promoteWho(obj)
            % Decides who in the node will be promoted
            promoteScore = zeros(1, obj.numPeople());
            promoteIndex = 1;
            bestScore = 0;
            for i = 1:obj.numPeople()
                promoteScore(i) = obj.peopleL(i).experience * obj.peopleL(i).quality;
                if promoteScore(i) > bestScore
                   promoteIndex = i;
                   bestScore = promoteScore(i);
                end
            end
            promoted = obj.peopleL(promoteIndex);
        end      
        
        function pd = probLevel(obj)
            spread = 1;
            if obj.level == 5
                prob = 10;
            elseif obj.level == 4
                prob = 8;
            elseif obj.level == 3
                prob = 4;
            elseif obj.level == 2
                prob = 2;
            else
                prob = 0.8;
                spread = 0.1;
            end
            pd = makedist('Triangular','a',prob-spread,'b',prob,'c',prob+spread);
        end
        
        function interactionL = personInteraction(obj)
            % Outputs a list of 1v1 interaction changes
            interactionL = [];
            for worker = obj.peopleL
                friends = obj.relationTo(worker);
                                
                friendInteractions = [0,0,0,0];
%                 for friend = 1:size(friends,2)
%                     friendInteractions = friendInteractions...
%                         + worker.interactWith(friends(friend)...
%                         , size(friends,2));
%                 end
                if ~isempty(friends)
                    for friend = friends
                        friendInteractions = friendInteractions...
                            + worker.interactWith(friend,...
                            size(friends, 2));
                    end
                end
                interactionL = [interactionL;friendInteractions];
            end
        end
        
        function interactionL = nodeInteraction(obj, totalEXP)
           % Outputs a list of person/node interaction changes
            interactionL = [];
            for worker = obj.peopleL
                interaction = obj.getWorkerDeltaFromEnvironment(worker, totalEXP);
                interactionL = [interactionL;interaction];
            end
        end 
        
        % Graph functions
        
        function obj = startRelation(obj)
            % Create the starting relation matrix
            numPeople = size(obj.peopleL,2);
            numRelations = numPeople - 1;
            while numRelations > 0
                relation = randperm(numPeople, 2);
                if obj.graph(relation(1),relation(2)) == 0
                    obj.graph(relation(1),relation(2)) = 1;
                    obj.graph(relation(2),relation(1)) = 1;
                    numRelations = numRelations -1;
                end
            end
        end
        
        function friend = relationTo(obj, worker)
            % Finds all of the friends of the input worker
            workerIndex = obj.peopleL == worker;
            friendIndex = obj.graph(:,workerIndex) == 1;
            friend = obj.peopleL(friendIndex);
        end
        
        function obj = addRelation(obj, personIndex)
            
            % Probability parameter
            alpha = 0.025;
            
            if rand < alpha
                relation = randi([1,size(obj.peopleL,2)], 1);
                if (obj.graph(personIndex,relation) == 0) && (personIndex ~= relation)
                    obj.graph(personIndex,relation) = 1;
                    obj.graph(relation,personIndex) = 1;
                end
            end
        end
        
        % Friends have (row + column)/2 number of friends

   

        % These functions alter the way in which workers in a node affect
        % the node and in which the node affects the workers.
        function deltaVector = getWorkerDeltaFromEnvironment(obj, person, totalExp)
            % The output of this function is a vector of changes to the
            % person.  (unhappiness, stress, experience, wage)
           
            a = 2 * 0.01;
            b = .25;
            c = 2 * 0.05;
            d = .25;
            e = 0.05;
            f = 0.002;
            g = 1;
            TEff = .8;
            
            sDelta = a * (TEff - obj.efficiency) * (1 + obj.numPositions)/...
                (1 + size(obj.peopleL,2)) * (1 - person.stress) + b * ...
                person.stress * obj.stress * (1 - person.stress) * ...
                (1 - obj.stress) * (obj.stress - person.stress);
            uDelta = c * ((obj.wages - person.wage)/obj.wages)^2 * ...
                sign(obj.wages - person.wage)*(1 - person.unhappiness)...
                * person.unhappiness + d * person.unhappiness...
                * obj.unhappiness * (1 - person.unhappiness)...
                * (1 - obj.unhappiness) * (obj.unhappiness...
                - person.unhappiness) + g * person.experience/totalExp;
            eDelta = e * abs(sqrt(obj.efficiency));
            wDelta = f * obj.efficiency;
            
            deltaVector = [uDelta, sDelta, eDelta, wDelta];
        end
        
        function deltaVector = getEnvironmentDeltaFromWorker(obj, person, totalExp)
            % The output of this function is a vector of changes to the
            % office environment as a result of an individual person in the
            % office.  (unhappiness, stress, efficiency, wage)
            
            g = 2 / (0.01 + size(obj.peopleL,2));
            h = 1.5 / (0.01 + size(obj.peopleL,2));
            
            uDelta = h * obj.unhappiness * person.unhappiness * ...
                (1 - obj.unhappiness) * (1 - person.unhappiness) * ...
                (person.unhappiness - obj.unhappiness);
            sDelta = g * obj.stress * person.stress * (1 - obj.stress) * ...
                (1 - person.stress) * (person.stress - obj.stress);
            
            deltaVector = [uDelta, sDelta, 0, 0];
        end
        
        function obj = newEfficiencyFinder(obj, totalExp)
            % This function edits the node and changes the efficiency
            % according to the worker-environment interaction rules.
            
            m = 160 / (0.01 + size(obj.peopleL,2));
            p = 0.8 / (0.01 + size(obj.peopleL,2));
            
            newEff = 0;
            
            for i = obj.peopleL
                newEff = newEff + m * i.quality * i.experience / totalExp + ...
                    p * (1 - i.stress)^2 * (1 - obj.stress)^2 * ...
                    (1 - i.unhappiness) * (1 - obj.unhappiness);
            end
            if newEff < 0
                newEff = 0;
            end
            if newEff > 1;
                newEff = 1;
            end
            obj.efficiency = newEff;
        end
        
        function obj = addDeltaMatrix(obj,deltaMatrix)
            % Adds the delta matrix (with the form [u,s,e{,w}]) to each worker.
            for workerIndex = 1:size(obj.peopleL,2)
                deltaVector = deltaMatrix(workerIndex,:);
                obj.peopleL(workerIndex).unhappiness = ...
                    obj.peopleL(workerIndex).unhappiness + deltaVector(1);
                obj.peopleL(workerIndex).stress = ...
                    obj.peopleL(workerIndex).stress + deltaVector(2);
                obj.peopleL(workerIndex).experience = ...
                    obj.peopleL(workerIndex).experience + deltaVector(3);
                if size(deltaVector,2) == 4
                    obj.peopleL(workerIndex).wage = ...
                    obj.peopleL(workerIndex).wage + deltaVector(4);
                end
            end
        end
        
        function deltaVector = addEnvironmentDeltaFromWorker(obj, totalExp)
            % Adds all of the delta vectors 
            deltaVector = zeros(1,4);
            for worker = obj.peopleL
                deltaVector = deltaVector + obj.getEnvironmentDeltaFromWorker(worker,totalExp);
            end
        end
        
        %  This function is a wrapper function which manages an entire
        %  timestep on a single node level.  It includes environment -
        %  worker interactions, worker - worker interactions, worker
        %  meditation interactions, and the addition of relations on the
        %  graph.
        function obj = nodePeopleInteractionsTimestep(obj, totalExp)
            % Outputs a changed node.  Requires as input the total experience
            % of the company.
            
            % One on one interactions
            oneVOneDeltaMatrix = obj.personInteraction();
            obj = obj.addDeltaMatrix(oneVOneDeltaMatrix);
            
            % Meditation interactions
            for person = obj.peopleL
                friends = obj.relationTo(person);
                numFriends = size(friends,2);
                person = person.meditate(numFriends);
            end
            
            % Environment - worker interactions
            workerEnvDeltaMatrix = obj.nodeInteraction(totalExp);
            envWorkerDeltaVector = obj.addEnvironmentDeltaFromWorker(totalExp);
            
            obj = obj.addDeltaMatrix(workerEnvDeltaMatrix);
            obj.unhappiness = obj.unhappiness + envWorkerDeltaVector(1);
            obj.stress = obj.stress + envWorkerDeltaVector(2);
            obj.efficiency = obj.efficiency + envWorkerDeltaVector(3);
            obj.wages = obj.wages + envWorkerDeltaVector(4);
            
            % New relation creation
            for personIndex = size(obj.peopleL,2)
                obj = obj.addRelation(personIndex);
            end
            
            obj.newEfficiencyFinder(totalExp);
            
        end
        
        function odds = nodeChurnChance(obj)
            % Finds the odds that some individual will churn from the node
            
            alpha = .04;
            beta = .04;
            
            odds = obj.churnOdds * ( alpha * obj.stress * ...
                obj.unhappiness^2 + beta * (1 - obj.efficiency)^3 );
            
        end
        
        function obj = effectOfChurn(obj, person)
            % Changes values due to the churn of person on other people 
            % and the node
            
            obj.stress = obj.stress + .5 * person.stress * ...
                (1 - obj.stress);
            for friend = obj.relationTo(person)
                friend.unhappiness = friend.unhappiness + .5 / ...
                    (size(obj.relationTo(person),2) + 0.01) * ...
                    person.unhappiness * (1 - friend.unhappiness);
            end
            for worker = obj.peopleL
                worker.stress = worker.stress + .1 * (1 - worker.stress);
            end
        end
                    
        function obj = toBeChurned(obj)
            % Selects an individual in the node to churn.  Removes them.
            
            alpha = 0.04;
            beta = 0.04;
            
            probList = zeros(1, size(obj.peopleL,2));
            
            experienceTot = 0;
            for person = obj.peopleL
                experienceTot = experienceTot + person.experience;
            end
            
            if size(obj.peopleL,2) ~= 1
                for i = 1:size(obj.peopleL,2)
                    worker = obj.peopleL(i);
                    probList(i) = alpha * worker.stress * ...
                        worker.unhappiness^2 + beta * ...
                        (1 - worker.experience / experienceTot) * ...
                        (1 - worker.quality); 
                end
            
                total = sum(probList);
                probList = probList .* 1/total;
            
                randomNumber = rand;
                for i = 1:size(obj.peopleL,2)
                    if randomNumber < probList(i)
                        churnedGuy = obj.peopleL(i);
                        break
                    end
                    churnedGuy = obj.peopleL(1);
                    % Dumb luck, dude.
                end
            
                obj = obj.effectOfChurn(churnedGuy);
            
                obj = obj.removePerson(churnedGuy);
            end
            
        end
        
        function churnLevel = churnTimestep(obj)
            % Runs a churn timestep on each node.  Gives an opportunity for
            % a node to churn an individual.  If they need to, chooses
            % someone to churn and churns them.
            
            randomNumber = rand;
            
            if randomNumber < obj.nodeChurnChance()
                obj = obj.toBeChurned();
                churnLevel = obj.level;
            else
                churnLevel = 0;
            end
        end
        
        function success = hiringTimestep(obj)
            % Runs a hiring timestep on each node. Gives an opportunity for
            % a node to hire an individual.  If they do, places a person
            % into the node.
            
            success = 0;
            numOpenSpots = obj.numPositions - size(obj.peopleL,2);
            pd = makedist('Triangular');
            pd1 = makedist('Triangular','a',0.1,'b',0.2,'c',0.3);
            pd2 = makedist('Triangular','a',0,'b',3,'c',10);
            
            
            for i = 1:numOpenSpots
                randomNumber = rand;
                if randomNumber < obj.hiringOdds
                     obj.addPerson(person(random(pd1,1,1)...
                        ,random(pd1,1,1),random(pd,1,1)...
                        ,random(pd2,1,1),random(makedist('Triangular','a',...
                        obj.prob-obj.spread,'b',obj.prob,'c',obj.prob+obj.spread),1,1)));
                    success = 1;
                end
            end
        end
        
    end % methods
end % classdef