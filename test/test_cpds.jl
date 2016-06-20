# StaticCPD
let
    df = DataFrame(a=randn(100))
    cpd = fit(StaticCPD{Normal}, df, :a)
    @test name(cpd) == :a
    @test parentless(cpd)
    @test parents(cpd) == NodeName[]
    @test disttype(cpd) <: Normal
    @test isa(cpd(Assignment()), Normal)
    @test pdf!(cpd, Assignment(:a=>0.5)) > 0.2
    @test pdf!(cpd, Assignment(:a=>0.0)) > pdf!(cpd, Assignment(:a=>0.5))
    @test logpdf!(cpd, Assignment(:a=>0.5)) > log(0.2)
    rand!(cpd, Assignment(:a=>0.5))
end

# CategoricalCPD
let

    # no parents
    let
        df = DataFrame(a=[1,2,1,2,3])
        cpd = fit(CategoricalCPD{Categorical}, df, :a)

        @test name(cpd) == :a
        @test parentless(cpd)

        d = cpd(Assignment())
        @test isa(d, Categorical) && isa(d, disttype(cpd))
        @test pdf(d, 1) == 0.4
        @test pdf(d, 2) == 0.4
        @test pdf(d, 3) == 0.2

        df = DataFrame(a=randn(100))
        cpd = fit(CategoricalCPD{Normal}, df, :a)

        @test isa(cpd(Assignment()), disttype(cpd))
        @test pdf!(cpd, Assignment(:a=>0.5)) > 0.2
        @test pdf!(cpd, Assignment(:a=>0.0)) > pdf!(cpd, Assignment(:a=>0.55))
    end

    # with parents
    let
        # Example with Categorical
        df = DataFrame(a=[1,2,1,2,3], b=[1,1,2,1,2])
        cpd = fit(CategoricalCPD{Categorical}, df, :b, [:a])

        @test name(cpd) == :b
        @test parents(cpd) == [:a]
        @test !parentless(cpd)

        @test cpd(Assignment(:a=>1)).p == [0.5,0.5]
        @test cpd(Assignment(:a=>2)).p == [1.0,0.0]
        @test cpd(Assignment(:a=>3)).p == [0.0,1.0]

        # Example with Bernoulli and more than one parent
        df = DataFrame(a=[   1,    1,    1,    1,    2,    2,    2,    2],
                       b=[   1,    1,    2,    2,    1,    1,    2,    2],
                       c=[true, true,false,false, true,false,false, true])
        cpd = fit(CategoricalCPD{Bernoulli}, df, :c, [:a, :b])

        @test isa(cpd(Assignment(:a=>1, :b=>1)), disttype(cpd))
        @test cpd(Assignment(:a=>1, :b=>1)).p == 1.0
        @test cpd(Assignment(:a=>1, :b=>2)).p == 0.0
        @test cpd(Assignment(:a=>2, :b=>1)).p == 0.5
        @test cpd(Assignment(:a=>2, :b=>2)).p == 0.5
    end
end

# Linear Gaussian
let

    # no parents
    let
        df = DataFrame(a=randn(100))
        cpd = fit(LinearGaussianCPD, df, :a, min_stdev=0.0)

        @test name(cpd) == :a
        @test parents(cpd) == NodeName[]
        @test parentless(cpd)
        @test disttype(cpd) <: Normal
        @test pdf!(cpd, Assignment(:a=>0.5)) > 0.2
        @test pdf!(cpd, Assignment(:a=>0.0)) > pdf!(cpd, Assignment(:a=>0.55))
    end

    # with parents
    let
        a = randn(1000)
        b = randn(1000) .+ 2*a .+ 1

        df = DataFrame(a=a, b=b)
        cpd = fit(LinearGaussianCPD, df, :b, [:a])

        @test !parentless(cpd)
        @test parents(cpd) == [:a]

        p = cpd(Assignment(:a=>0.0))
        @test isapprox(p.μ, 1.0, atol=0.25)
        @test isapprox(p.σ, 2.0, atol=0.50)

        p = cpd(Assignment(:a=>1.0))
        @test isapprox(p.μ, 3.0, atol=0.25)
        @test isapprox(p.σ, 2.0, atol=0.50)

        cpd = fit(LinearGaussianCPD, df, :b, [:a], min_stdev=10.0)
        @test cpd(Assignment(:a=>1.0)).σ == 10.0
    end
end

# ConditionalLinearGaussianCPD
let

    # no parents
    let
        df = DataFrame(a=randn(10))
        cpd = fit(ConditionalLinearGaussianCPD, df, :a)

        @test name(cpd) == :a
        @test parentless(cpd)

        d = cpd(Assignment())
        @test isa(d, Normal) && isa(d, disttype(cpd))
    end

    # with parents
    let
        df = DataFrame(a=[  1,   1,   1,   1,     2,   2,   2,   2],
                       b=[0.5, 1.0, 1.5, 1.0,   2.5, 3.0, 3.5, 3.0],
                       c=[0.55,1.05,1.53,1.02,  2.52,3.01,3.55,3.03])
        cpd = fit(ConditionalLinearGaussianCPD, df, :c, [:a, :b])

        @test name(cpd) == :c
        @test parents(cpd) == [:a, :b]
        @test !parentless(cpd)

        d = cpd(Assignment(:a=>1, :b=>0.5))
        @test isapprox(d.μ, 0.538, atol=0.001)
        @test isapprox(d.σ, 1.130, atol=0.001)

        d = cpd(Assignment(:a=>2, :b=>3.0))
        @test isapprox(d.μ, 3.029, atol=0.001)
        @test isapprox(d.σ, 1.130, atol=0.001)
    end
end