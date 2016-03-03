clear
clc



T = 730;

tic
c = company(T);
c.simulation();
toc

c.churnRecord
sum(c.churnRecord)
c.hiringExpenditures

for branch = c.network
    if isnan(branch.unhappiness)
        'Halp Branch U'
        branch.name
    end
    for person = branch.peopleL
        if isnan(person.unhappiness)
            'Halp U'
            branch.name
        end
        if isnan(person.experience)
            'Halp E'
            branch.name
        end
    end
end

c.network(1).plotHistory();
c.network(6).plotHistory();
c.network(12).plotHistory();
c.network(19).plotHistory();
c.network(20).plotHistory();
c.network(21).plotHistory();
c.network(24).plotHistory();
c.network(25).plotHistory();
c.network(35).plotHistory();