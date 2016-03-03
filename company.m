classdef company < handle
    %System:
    %   Detailed explanation goes here
    
    properties 
        network                % An array of pointers to nodes (representing the network of the business)
        timeSteps              % The number of time steps to be run
        totalExpHist           % Keep track of total exp
        churnRecord            % [L1 L2 L3 L4 L5], number of churns at level
        hiringExpenditures     % Accumulator for hiring values.
    end
    
    methods
        function obj = company(timeSteps)
            % Set up the company (hardcode) and save the number of time
            % steps
            hardcode
            obj.network = nodeL;
            obj.timeSteps = timeSteps;
            obj.churnRecord = zeros(1,5);
            obj.hiringExpenditures = 0;
        end
        
        function totalExperience = totalExp(obj)
            % Calculates the total experience of the company
            totalExperience = 0;
            for branch = obj.network
                for worker = branch.peopleL
                    totalExperience = totalExperience + worker.experience;
                end
            end
            obj.totalExpHist = [obj.totalExpHist, totalExperience];
        end
        
        function obj = simulation(obj)
            for day = 1:obj.timeSteps
                
                if isnan(obj.totalExp())
                    'OH GOD IT IS WRONG!'
                end
                
                %deltaVector = zeros(1,4);
                for branch = obj.network
                    
                    branch.timeStep(obj.totalExp());
                    
                    if mod(day, 7) == 0 % weekly
                        nodePropDeltaVec = branch.nodePropagation(); % [S U]
                        branch.stress = branch.stress + nodePropDeltaVec(1);
                        branch.unhappiness = branch.unhappiness...
                            + nodePropDeltaVec(2);
                    end
                    
                    if mod(day, 30) == 0 % monthly
                        hired = branch.hiringTimestep();
                        churnLevel = branch.churnTimestep();
                        branch.promote();
                        
                        if churnLevel ~= 0
                            obj.churnRecord(churnLevel) =...
                                obj.churnRecord(churnLevel) + 1;
                        end
                        
                        if hired == 1
                            switch branch.level
                                case 1
                                    obj.hiringExpenditures =...
                                        obj.hiringExpenditures + 0.4;
                                case 2
                                    obj.hiringExpenditures =...
                                        obj.hiringExpenditures + 0.8;
                                case 3
                                    obj.hiringExpenditures =...
                                        obj.hiringExpenditures + 1.2;
                                case 4
                                    obj.hiringExpenditures =...
                                        obj.hiringExpenditures + 1.8;
                            end
                        end
                    end
                end
            end
        end
        
        function saveAll(obj)
            for branch = obj.network
                h = branch.plotHistory();
                saveas(h,branch.name,'jpg')
            end
            close all;
        end
    end
    
end